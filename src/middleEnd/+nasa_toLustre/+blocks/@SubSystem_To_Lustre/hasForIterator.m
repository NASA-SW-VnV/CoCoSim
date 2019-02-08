
function [b, Iteratorblk] = hasForIterator(blk)
    fields = fieldnames(blk.Content);
    fields = ...
        fields(...
        cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
    forIteratorFields = fields(...
        cellfun(@(x) strcmp(blk.Content.(x).BlockType,'ForIterator'), fields));
    b = ~isempty(forIteratorFields);

    if b
        Iteratorblk = blk.Content.(forIteratorFields{1});
    else
        Iteratorblk = [];
    end
end
