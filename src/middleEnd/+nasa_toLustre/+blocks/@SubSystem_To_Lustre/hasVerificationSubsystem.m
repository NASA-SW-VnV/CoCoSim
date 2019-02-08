
function [b, hasNoOutputs, vsBlk] = hasVerificationSubsystem(blk)
    fields = fieldnames(blk.Content);
    fields = ...
        fields(...
        cellfun(@(x) isfield(blk.Content.(x),'MaskType'), fields));
    vFields = fields(...
        cellfun(@(x) ...
        strcmp(blk.Content.(x).MaskType,'VerificationSubsystem'), ...
        fields));
    b = ~isempty(vFields);
    if b
        vsBlk = blk.Content.(vFields{1});
        hasNoOutputs = isempty(vsBlk.CompiledPortWidths.Outport);
    else
        vsBlk = [];
        hasNoOutputs = [];
    end

end
