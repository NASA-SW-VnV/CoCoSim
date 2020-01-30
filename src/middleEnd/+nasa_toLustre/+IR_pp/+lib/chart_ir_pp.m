function [ ir ] = chart_ir_pp( ir )
    %chart_ir_pp adapt stateflow chart to lustref compiler
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    file_path = ir.meta.file_path;
    [~, file_name, ~] = fileparts(file_path);
    field_name = IRUtils.name_format(file_name);
    chart_list = find_system(file_name,'LookUnderMasks', 'all',...
        'SFBlockType', 'Chart');
    if isempty(chart_list)
        return;
    end
    if isfield(ir, field_name)
        ir.(field_name) = recursiveCall(ir.(field_name));
    end
end
%
function blk = recursiveCall(blk)
    if isfield(blk, 'SFBlockType') ...
            && strcmp(blk.SFBlockType, 'Chart')
        display_msg(sprintf('pre-processing Chart %s.', blk.Origin_path), ...
            MsgType.INFO, 'chart_ir_pp', '');
        blk.StateflowContent = ...
            nasa_toLustre.IR_pp.stateflow_IR_pp.stateflow_IR_pp(blk.StateflowContent);
    elseif isfield(blk, 'Content') && ~isempty(blk.Content)
        field_names = fieldnames(blk.Content);
        for i=1:numel(field_names)
            blk.Content.(field_names{i}) = recursiveCall(blk.Content.(field_names{i}));
        end
    end
end
