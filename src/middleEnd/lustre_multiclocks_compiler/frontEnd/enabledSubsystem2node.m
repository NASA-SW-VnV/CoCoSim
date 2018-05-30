function [ main_node] = enabledSubsystem2node( subsys_struct, main_sampleTime, xml_trace)
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
isConditionalSubsys = 1;
is_main_node = 0;
[blk_name, node_inputs, node_outputs, node_inputs_withoutDT, node_outputs_withoutDT] = ...
                SLX2LusUtils.extractNodeHeader(subsys_struct, is_main_node, isConditionalSubsys, main_sampleTime, xml_trace);
node_name = strcat(blk_name, '_automaton');
node_header = sprintf('node %s (%s)\n returns (%s);',...
    node_name, node_inputs, node_outputs);

% creating contract
contract = '-- Contract In progress';
% Body code
[body, variables_str] = write_automaton(subsys_struct, blk_name, ...
    node_inputs_withoutDT, node_outputs_withoutDT, xml_trace);

main_node = sprintf('%s\n%s\n%s\n%s\nlet\n\t%s\ntel',...
    comment, node_header, contract, variables_str, body);


end



function [body, variables_str] =...
    write_automaton(subsys, blk_name, ...
    node_inputs_withoutDT, node_outputs_withoutDT, xml_trace)

% get the original node call
original_node_call = ...
    sprintf('(%s) = %s(%s);\n\t',...
    node_inputs_withoutDT,...
    blk_name, ...
    node_outputs_withoutDT);


fields = fieldnames(subsys.Content);
enablePortsFields = fields(...
    cellfun(@(x) (isfield(subsys.Content.(x),'BlockType')...
    && (strcmp(subsys.Content.(x).BlockType,'EnablePort') ...
        || strcmp(subsys.Content.(x).BlockType,'ActionPort')) ), fields));
if isempty(enablePortsFields)
    %the case of trigger port only
    resumeOrRestart = 'resume';% by default
else
    if strcmp(subsys.Content.(enablePortsFields{1}).BlockType, 'EnablePort')
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
        outport_blk.CompiledPortDataTypes.Inport{1}, outport_blk.CompiledPortWidths.Inport);
    for out_idx=1:numel(outputs_i)
        variables_cell{end + 1} = sprintf('pre_%s',outputs_DT_i{out_idx});
        inactiveStatement = sprintf('%s %s = pre_%s;\n\t', ...
            inactiveStatement, outputs_i{out_idx}, outputs_i{out_idx});
        if strcmp(OutputWhenDisabled, 'reset') && ~isempty(enablePortsFields)
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


