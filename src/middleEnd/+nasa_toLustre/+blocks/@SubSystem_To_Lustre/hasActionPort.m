
function [b, StatesWhenEnabling] = hasActionPort(blk)
    fields = fieldnames(blk.Content);
    fields = ...
        fields(...
        cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
    enablePortsFields = fields(...
        cellfun(@(x) strcmp(blk.Content.(x).BlockType,'ActionPort'), fields));
    b = ~isempty(enablePortsFields);

    if b
        StatesWhenEnabling = blk.Content.(enablePortsFields{1}).InitializeStates;
    else
        StatesWhenEnabling = '';
    end
end
