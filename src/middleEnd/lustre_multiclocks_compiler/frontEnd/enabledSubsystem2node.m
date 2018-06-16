function [ main_node] = enabledSubsystem2node( subsys_struct, hasEnablePort, hasActionPort, hasTriggerPort, main_sampleTime, xml_trace)
%enabledSubsystem2node create an automaton lustre node for
%enabled/triggered/Action subsystem
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
if hasTriggerPort && hasEnablePort
    isEnableORAction = 0;
    isEnableAndTrigger = 1;
else
    isEnableORAction = 1;
    isEnableAndTrigger = 0;
end
is_main_node = 0;
[blk_name, node_inputs, node_outputs, node_inputs_withoutDT, node_outputs_withoutDT] = ...
    SLX2LusUtils.extractNodeHeader(subsys_struct, is_main_node, isEnableORAction, isEnableAndTrigger, main_sampleTime, xml_trace);
node_name = strcat(blk_name, '_automaton');
node_header = sprintf('node %s (%s)\n returns (%s);',...
    node_name, node_inputs, node_outputs);

% creating contract
contract = '';
if isfield(subsys_struct, 'ContractNodeNames')
    contractCell = {};
    contractCell{1} = '(*@contract';
    for i=1:numel(subsys_struct.ContractNodeNames)
        contractCell{end+1} = sprintf('import %s( %s ) returns (%s);', ...
            subsys_struct.ContractNodeNames{i}, node_inputs_withoutDT, node_outputs_withoutDT);
    end
    contractCell{end+1} = '*)';
    contract = MatlabUtils.strjoin(contractCell, '\n');
end
% Body code
if isEnableAndTrigger
    % the case of enabledTriggered subsystem
    [body, variables_str] = write_enabled_AND_triggered_action_SS(subsys_struct, blk_name, ...
        node_inputs_withoutDT, node_outputs_withoutDT, xml_trace);
else
    [body, variables_str] = write_enabled_OR_triggered_OR_action_SS(subsys_struct, blk_name, ...
        node_inputs_withoutDT, node_outputs_withoutDT, hasEnablePort, hasActionPort, hasTriggerPort, xml_trace);
    
end

main_node = sprintf('%s\n%s\n%s\n%s\nlet\n\t%s\ntel',...
    comment, node_header, contract, variables_str, body);


end


%%
function [body, variables_str] =...
    write_enabled_OR_triggered_OR_action_SS(subsys, blk_name, ...
    node_inputs_withoutDT, node_outputs_withoutDT, hasEnablePort, hasActionPort, hasTriggerPort, xml_trace, original_node_call)

% get the original node call
if ~exist('original_node_call', 'var')
    original_node_call = ...
        sprintf('(%s) = %s(%s);\n\t',...
        node_outputs_withoutDT,...
        blk_name, ...
        node_inputs_withoutDT);
end


fields = fieldnames(subsys.Content);
enablePortsFields = fields(...
    cellfun(@(x) (isfield(subsys.Content.(x),'BlockType')...
    && (strcmp(subsys.Content.(x).BlockType,'EnablePort') ...
    || strcmp(subsys.Content.(x).BlockType,'ActionPort')) ), fields));
if hasTriggerPort && ~(hasEnablePort && hasActionPort)
    %the case of trigger port only
    resumeOrRestart = 'resume';% by default
else
    if hasEnablePort
        StatesWhenEnabling = subsys.Content.(enablePortsFields{1}).StatesWhenEnabling;
    else
        StatesWhenEnabling = subsys.Content.(enablePortsFields{1}).InitializeStates;
    end
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
    [outputs_i, outputs_DT_i] = SLX2LusUtils.getBlockOutputsNames(subsys, outport_blk);
    OutputWhenDisabled = outport_blk.OutputWhenDisabled;
    InitialOutput_cell = SLX2LusUtils.getInitialOutput(subsys, outport_blk,...
        outport_blk.InitialOutput, outport_blk.CompiledPortDataTypes.Inport{1}, outport_blk.CompiledPortWidths.Inport);
    for out_idx=1:numel(outputs_i)
        variables_cell{end + 1} = sprintf('pre_%s',outputs_DT_i{out_idx});
        inactiveStatement = sprintf('%s %s = pre_%s;\n\t', ...
            inactiveStatement, outputs_i{out_idx}, outputs_i{out_idx});
        if strcmp(OutputWhenDisabled, 'reset') && (hasActionPort || hasEnablePort)
            pre_out_str = sprintf('%spre_%s = %s;\n\t',...
                pre_out_str, outputs_i{out_idx}, InitialOutput_cell{out_idx});
        else
            pre_out_str = sprintf('%spre_%s = if %s > 0.0 then pre(%s) else %s;\n\t',...
                pre_out_str, outputs_i{out_idx}, SLX2LusUtils.timeStepStr(), ...
                outputs_i{out_idx}, InitialOutput_cell{out_idx});
        end
    end
end
%
body_template = 'automaton enabled_%s\n\t';
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
automaton = sprintf(body_template, ...
    blk_name,...
    blk_name,...
    SLX2LusUtils.isEnabledStr(), blk_name,...
    original_node_call, ...
    blk_name,...
    SLX2LusUtils.isEnabledStr(), resumeOrRestart, blk_name,...
    inactiveStatement);
body = sprintf('%s\n\t%s', pre_out_str, automaton);
variables_str = MatlabUtils.strjoin(variables_cell, '\n\t');
if ~isempty(variables_str)
    variables_str = ['var ' variables_str];
end
end

%%
function [body, variables_str] = write_enabled_AND_triggered_action_SS(subsys, blk_name, ...
    node_inputs_withoutDT, node_outputs_withoutDT, xml_trace)
% get the original node call
original_node_call = ...
    sprintf('(%s) = %s(%s);\n\t',...
    node_outputs_withoutDT,...
    blk_name, ...
    node_inputs_withoutDT);


fields = fieldnames(subsys.Content);

Outportfields = ...
    fields(cellfun(@(x) (isfield(subsys.Content.(x),'BlockType')...
    && strcmp(subsys.Content.(x).BlockType, 'Outport')), fields));
variables_cell = {};
pre_out_str = '';
inactiveStatement = '';
for i=1:numel(Outportfields)
    outport_blk = subsys.Content.(Outportfields{i});
    [outputs_i, outputs_DT_i] = SLX2LusUtils.getBlockOutputsNames(subsys, outport_blk);
    OutputWhenDisabled = outport_blk.OutputWhenDisabled;
    InitialOutput_cell = SLX2LusUtils.getInitialOutput(subsys, outport_blk,...
        outport_blk.InitialOutput, ...
        outport_blk.CompiledPortDataTypes.Inport{1}, outport_blk.CompiledPortWidths.Inport);
    for out_idx=1:numel(outputs_i)
        if strcmp(OutputWhenDisabled, 'reset') 
            var_name = sprintf('pre_held_%s',outputs_DT_i{out_idx});
            variables_cell{end + 1} = var_name;
            pre_out_str = sprintf('%spre_held_%s = if %s > 0.0 then pre(%s) else %s;\n\t',...
                pre_out_str, outputs_i{out_idx}, SLX2LusUtils.timeStepStr(), ...
                outputs_i{out_idx}, InitialOutput_cell{out_idx});
            inactiveStatement = sprintf('%s %s = pre_held_%s;\n\t\t', ...
                inactiveStatement, outputs_i{out_idx}, outputs_i{out_idx});
        else
            inactiveStatement = sprintf('%s %s = pre_%s;\n\t\t', ...
                inactiveStatement, outputs_i{out_idx}, outputs_i{out_idx});
        end
    end
end
%
body_template = '\tautomaton triggered_%s\n\t\t';
body_template = [body_template, 'state Active_triggered_%s:\n\t\t'];
body_template = [body_template, 'unless (not %s) resume Inactive_triggered_%s\n\t\t'];
body_template = [body_template, 'let\n\t\t'];
body_template = [body_template, ' %s\n\t\t'];%call of subsystem
body_template = [body_template, 'tel\n\t\t'];
body_template = [body_template, 'state Inactive_triggered_%s:\n\t\t'];
body_template = [body_template, 'unless %s resume Active_triggered_%s\n\t\t'];
body_template = [body_template, 'let\n\t\t'];
body_template = [body_template, ' %s\n\t\t'];%out = pre_out;
body_template = [body_template, 'tel\n\t\t'];
automaton = sprintf(body_template, ...
    blk_name,...
    blk_name,...
    SLX2LusUtils.isTriggeredStr(), blk_name,...
    original_node_call, ...
    blk_name,...
    SLX2LusUtils.isTriggeredStr(), blk_name,...
    inactiveStatement);
[bodyEnabledTriggered, variables_str_enabled] =...
    write_enabled_OR_triggered_OR_action_SS(subsys, blk_name, ...
    node_inputs_withoutDT, node_outputs_withoutDT, 1, 0, 0, xml_trace, automaton);
body = sprintf('%s\n\t%s', pre_out_str, bodyEnabledTriggered);
variables_str = MatlabUtils.strjoin(variables_cell, '\n\t');
if ~isempty(variables_str_enabled)
    variables_str =sprintf('%s\n\t%s', variables_str_enabled, variables_str);
elseif ~isempty(variables_str)
    variables_str = ['var ' variables_str];
end
end

