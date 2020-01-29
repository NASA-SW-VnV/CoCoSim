function [b, ShowOutputPortIsOn, StatesWhenEnabling] = hasEnablePort(blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    if isfield(blk, 'Content')
        fields = fieldnames(blk.Content);
        fields = ...
            fields(...
            cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
        enablePortsFields = fields(...
            cellfun(@(x) strcmp(blk.Content.(x).BlockType,'EnablePort'), fields));
        b = ~isempty(enablePortsFields);
    else
        b = false;
    end
    
    if b
        ShowOutputPortIsOn =  ...
            strcmp(blk.Content.(enablePortsFields{1}).ShowOutputPort, 'on');
        StatesWhenEnabling = blk.Content.(enablePortsFields{1}).StatesWhenEnabling;
    else
        ShowOutputPortIsOn = 0;
        StatesWhenEnabling = '';
    end
end
