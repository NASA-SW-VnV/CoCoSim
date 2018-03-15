function [ main_node] = enabledSubsystem2node( subsys_struct, xml_trace)
%enabledSubsystem2node create an automaton lustre node for enabled subsystem
%INPUTS:
%   subsys_struct: The internal representation of the subsystem.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% Adding lustre comments tracking the original path
origin_path = regexprep(subsys_struct.Origin_path, '(\\n|\n)', '--');
comment = sprintf('-- Original block name: %s', origin_path);

% creating node header
blk_name = SLX2LusUtils.node_name_format(subsys_struct);
node_name = strcat(blk_name, '_automaton');
[node_inputs_cell, node_inputs_withoutDT_cell] = SLX2LusUtils.extract_node_InOutputs_withDT(subsys_struct, 'Inport', xml_trace);
if isempty(node_inputs_cell)
    node_inputs_cell{1} = '_virtual:bool;';
    node_inputs_withoutDT_cell{1} = '_virtual';
end
node_inputs = MatlabUtils.strjoin(node_inputs_cell, '\n');
node_inputs = [node_inputs, ...
    strcat(SLX2LusUtils.isEnabledStr() , ':bool;')];
[node_outputs_cell, node_outputs_withoutDT_cell] = SLX2LusUtils.extract_node_InOutputs_withDT(subsys_struct, 'Outport', xml_trace);
node_outputs = MatlabUtils.strjoin(node_outputs_cell, '\n');

node_header = sprintf('node %s (%s)\n returns (%s);',...
    node_name, node_inputs, node_outputs);

% creating contract
contract = '-- Contract In progress';


% Body code
[body, variables_str] = write_automaton(subsys_struct, blk_name, ...
    node_inputs_withoutDT_cell, node_outputs_withoutDT_cell, xml_trace);

main_node = sprintf('%s\n%s\n%s\n%s\nlet\n\t%s\ntel',...
    comment, node_header, contract, variables_str, body);


end



function [body, variables_str] =...
    write_automaton(subsys, blk_name, ...
    node_inputs_withoutDT_cell, node_outputs_withoutDT_cell, xml_trace)

% get the original node call
original_node_call = ...
    sprintf('(%s) = %s(%s);\n\t',...
    MatlabUtils.strjoin(node_outputs_withoutDT_cell, ',\n\t '),...
    blk_name, ...
    MatlabUtils.strjoin(node_inputs_withoutDT_cell, ',\n\t\t'));


fields = fieldnames(subsys.Content);
enablePortsFields = fields(...
    cellfun(@(x) (isfield(subsys.Content.(x),'BlockType')...
    && strcmp(subsys.Content.(x).BlockType,'EnablePort')), fields));
if isempty(enablePortsFields)
    %the case of trigger port only
    resumeOrRestart = 'resume';% by default
else
    StatesWhenEnabling = subsys.Content.(enablePortsFields{1}).StatesWhenEnabling;
    if strcmp(StatesWhenEnabling, 'reset')
        resumeOrRestart = 'restart';
    else
        resumeOrRestart = 'resume';
    end
end
Outportfields = ...
    fields(cellfun(@(x) (isfield(subsys.Content.(x),'BlockType')...
    && strcmp(subsys.Content.(x).BlockType, 'Outport')), fields));
variables_cell = {};
pre_out_str = '';
inactiveStatement = '';
for i=1:numel(Outportfields)
    outport_blk = subsys.Content.(Outportfields{i});
    [outputs_i, outputs_DT_i] = SLX2LusUtils.getBlockOutputsNames(outport_blk);
    OutputWhenDisabled = outport_blk.OutputWhenDisabled;
    InitialOutput_cell = getInitialOutput(subsys, outport_blk);
    for out_idx=1:numel(outputs_i)
        variables_cell{end + 1} = sprintf('pre_%s',outputs_DT_i{out_idx});
        inactiveStatement = sprintf('%s %s = pre_%s;\n\t', ...
            inactiveStatement, outputs_i{out_idx}, outputs_i{out_idx});
        if strcmp(OutputWhenDisabled, 'reset') && ~isempty(enablePortsFields)
            pre_out_str = sprintf('%spre_%s = %s;\n\t',...
                pre_out_str, outputs_i{out_idx}, InitialOutput_cell{i});
        else
            pre_out_str = sprintf('%spre_%s = pre(%s);\n\t',...
                pre_out_str, outputs_i{out_idx},...
                 outputs_i{out_idx});
        end
    end
end
%
body_template = '%s\n\t';%pre_out = ...;
body_template = [body_template, 'automaton enabled_%s\n\t'];
body_template = [body_template, 'state Active_%s:\n\t'];
body_template = [body_template, 'unless (not %s) restart Inactive_%s\n\t'];
body_template = [body_template, 'let\n\t'];
body_template = [body_template, ' %s\n\t'];%call of subsystem
body_template = [body_template, 'tel\n\t'];
body_template = [body_template, 'state Inactive_%s:\n\t'];
body_template = [body_template, 'unless %s %s Active_%s\n\t'];
body_template = [body_template, 'let\n\t'];
body_template = [body_template, ' %s\n\t'];%out = pre_out;
body_template = [body_template, 'tel\n\t'];
body = sprintf(body_template, pre_out_str, ...
    blk_name,...
    blk_name,...
    SLX2LusUtils.isEnabledStr(), blk_name,...
    original_node_call, ...
    blk_name,...
    SLX2LusUtils.isEnabledStr(), resumeOrRestart, blk_name,...
    inactiveStatement);
variables_str = MatlabUtils.strjoin(variables_cell, '\n\t');
if ~isempty(variables_str)
    variables_str = ['var ' variables_str];
end
end

% Get the initial ouput of Outport depending on the dimension.
function InitialOutput_cell = getInitialOutput(parent, blk)
lus_outputDataType = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{1});
if strcmp(blk.InitialOutput, '[]')
    InitialOutput = '0';
else
    InitialOutput = blk.InitialOutput;
end
[InitialOutputValue, InitialOutputType, status] = ...
    Constant_To_Lustre.getValueFromParameter(parent, blk, InitialOutput);
if status
    display_msg(sprintf('InitialOutput %s in block %s not found neither in Matlab workspace or in Model workspace',...
        blk.InitialOutput, blk.Origin_path), ...
        MsgType.ERROR, 'Outport_To_Lustre', '');
    return;
end
[value_inlined, status, msg] = MatlabUtils.inline_values(InitialOutputValue);
if status
    %message
    display_msg(msg,MsgType.ERROR, 'Outport_To_Lustre', '');
    return;
end
InitialOutput_cell = {};
for i=1:numel(value_inlined)
    if strcmp(lus_outputDataType, 'real')
        InitialOutput_cell{i} = sprintf('%.15f', value_inlined(i));
    elseif strcmp(lus_outputDataType, 'int')
        InitialOutput_cell{i} = sprintf('%d', int32(value_inlined(i)));
    elseif strcmp(lus_outputDataType, 'bool')
        if value_inlined(i)
            InitialOutput_cell{i} = 'true';
        else
            InitialOutput_cell{i} = 'false';
        end
    elseif strncmp(InitialOutputType, 'int', 3) ...
            || strncmp(InitialOutputType, 'uint', 4)
        InitialOutput_cell{i} = num2str(value_inlined(i));
    elseif strcmp(InitialOutputType, 'boolean') || strcmp(InitialOutputType, 'logical')
        if value_inlined(i)
            InitialOutput_cell{i} = 'true';
        else
            InitialOutput_cell{i} = 'false';
        end
    else
        InitialOutput_cell{i} = sprintf('%.15f', value_inlined(i));
    end
end
if numel(InitialOutput_cell) < blk.CompiledPortWidths.Inport
    InitialOutput_cell = arrayfun(@(x) {InitialOutput_cell{1}}, (1:numel(outputs)));
end

end

