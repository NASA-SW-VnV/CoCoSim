
function [b, ResetType] = hasResetPort(blk)
    fields = fieldnames(blk.Content);
    fields = ...
        fields(...
        cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
    resetPortsFields = fields(...
        cellfun(@(x) strcmp(blk.Content.(x).BlockType,'ResetPort'), fields));
    b = ~isempty(resetPortsFields);

    if b
        ResetType = blk.Content.(resetPortsFields{1}).ResetTriggerType;
    else
        ResetType = '';
    end
end
