function [b, StatesWhenEnabling] = hasActionPort(blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isfield(blk, 'Content')
        fields = fieldnames(blk.Content);
        fields = ...
            fields(...
            cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
        enablePortsFields = fields(...
            cellfun(@(x) strcmp(blk.Content.(x).BlockType,'ActionPort'), fields));
        b = ~isempty(enablePortsFields);
    else
        b = false;
    end
    
    if b
        StatesWhenEnabling = blk.Content.(enablePortsFields{1}).InitializeStates;
    else
        StatesWhenEnabling = '';
    end
end
