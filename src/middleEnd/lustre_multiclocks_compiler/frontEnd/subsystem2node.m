function [ main_node, external_nodes, external_libraries ] = subsystem2node( subsys_struct,  main_sampleTime, is_main_node, xml_trace)
%BLOCK_TO_LUSTRE create a lustre node for every Simulink subsystem within
%subsys_struc.
%INPUTS:
%   subsys_struct: The internal representation of the subsystem.
%   main_clock   : The model sample time.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initializing outputs
external_nodes = '';
main_node = '';
external_libraries = {};
if ~exist('is_main_node', 'var')
    is_main_node = 0;
end
% Adding lustre comments tracking the original path
origin_path = regexprep(subsys_struct.Origin_path, '(\\n|\n)', '--');
comment = sprintf('-- Original block name: %s', origin_path);

% creating node header
isContractBlk = isfield(subsys_struct, 'MaskType') ...
        && strcmp(subsys_struct.MaskType, 'ContractBlock');
isEnableORAction = 0;
isEnableAndTrigger = 0;
[node_name, node_inputs, node_outputs, node_inputs_withoutDT, node_outputs_withoutDT] = ...
                SLX2LusUtils.extractNodeHeader(subsys_struct, is_main_node, isEnableORAction, isEnableAndTrigger, main_sampleTime, xml_trace);
if isContractBlk
    node_header = sprintf('contract %s (%s)\n returns (%s);',...
        node_name, node_inputs, node_outputs);
else
    node_header = sprintf('node %s (%s)\n returns (%s);',...
        node_name, node_inputs, node_outputs);
end
% Body code
[body, variables_str, external_nodes, external_libraries] = write_body(subsys_struct, main_sampleTime, xml_trace);
if is_main_node
    if ~isempty(node_outputs)
        if ~isempty(variables_str)
            variables_str = [variables_str sprintf('\n\t%s:real;', SLX2LusUtils.timeStepStr())];
        else
            variables_str = ['var ' sprintf('%s:real;', SLX2LusUtils.timeStepStr())];
        end
    end
    body = [sprintf('%s = 0.0 -> pre %s + %.15f;\n\t', ...
        SLX2LusUtils.timeStepStr(), SLX2LusUtils.timeStepStr(), main_sampleTime(1)), body];
    %define all clocks if needed
    clocks = subsys_struct.AllCompiledSampleTimes;
    if numel(clocks) > 1
        c = {};
        for i=1:numel(clocks)
            T = clocks{i};
            st_n = T(1)/main_sampleTime(1);
            ph_n = T(2)/main_sampleTime(1);
            if ~((st_n == 1 || st_n == 0) && ph_n == 0)
                body = [sprintf('%s = _make_clock(%.0f, %.0f);\n\t', ...
                    SLX2LusUtils.clockName(st_n, ph_n), st_n, ph_n), body];
                c{end+1} = SLX2LusUtils.clockName(st_n, ph_n);
            end
        end
        c = MatlabUtils.strjoin(c, ', ');
        if ~isempty(variables_str)
            variables_str = [variables_str sprintf('\n\t%s:bool clock;', c)];
        else
            variables_str = ['var ' sprintf('%s:bool clock;', c)];
        end
        if ~isempty(c), external_libraries{end+1} = '_make_clock'; end
    end
end

hasEnablePort = SubSystem_To_Lustre.hasEnablePort(subsys_struct);
hasActionPort = SubSystem_To_Lustre.hasActionPort(subsys_struct);
hasTriggerPort = SubSystem_To_Lustre.hasTriggerPort(subsys_struct);
isConditialSS = hasEnablePort || hasActionPort || hasTriggerPort;
% creating contract
contract = '';
if ~isConditialSS && isfield(subsys_struct, 'ContractNodeNames')
    contractCell = {};
    contractCell{1} = '(*@contract';
    for i=1:numel(subsys_struct.ContractNodeNames)
        contractCell{end+1} = sprintf('import %s( %s ) returns (%s);', ...
            subsys_struct.ContractNodeNames{i}, node_inputs_withoutDT, node_outputs_withoutDT);
    end
    contractCell{end+1} = '*)';
    contract = MatlabUtils.strjoin(contractCell, '\n');
end


main_node = sprintf('%s\n%s\n%s\n%s\nlet\n\t%s\ntel\n',...
    comment, node_header, contract, variables_str, body);

if  isConditialSS
    automaton_node = enabledSubsystem2node(subsys_struct, hasEnablePort, hasActionPort, hasTriggerPort, main_sampleTime,...
        xml_trace);
    main_node = [main_node, automaton_node];
end
end


%%
function [body, variables_str, external_nodes, external_libraries] =...
    write_body(subsys, main_sampleTime, xml_trace)
variables_str = '';
body = '';
external_nodes = '';
external_libraries = {};


fields = fieldnames(subsys.Content);
fields = ...
    fields(cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));

for i=1:numel(fields)
    blk = subsys.Content.(fields{i});
    [b, status] = getWriteType(blk);
    if status
        continue;
    end
    b.write_code(subsys, blk, main_sampleTime, xml_trace);
    body = [body, b.getCode()];
    variables_str = [variables_str, char(MatlabUtils.strjoin(b.variables, '\n\t'))];
    external_nodes = [external_nodes, b.external_nodes];
    external_libraries = [external_libraries, b.external_libraries];
end
if ~isempty(variables_str)
    variables_str = ['var ' variables_str];
end
end


