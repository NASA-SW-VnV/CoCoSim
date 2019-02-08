
function [b, ShowOutputPortIsOn, StatesWhenEnabling] = hasEnablePort(blk)
    fields = fieldnames(blk.Content);
    fields = ...
        fields(...
        cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
    enablePortsFields = fields(...
        cellfun(@(x) strcmp(blk.Content.(x).BlockType,'EnablePort'), fields));
    b = ~isempty(enablePortsFields);

    if b
        ShowOutputPortIsOn =  ...
            strcmp(blk.Content.(enablePortsFields{1}).ShowOutputPort, 'on');
        StatesWhenEnabling = blk.Content.(enablePortsFields{1}).StatesWhenEnabling;
    else
        ShowOutputPortIsOn = 0;
        StatesWhenEnabling = '';
    end
end
