function [b, ResetType] = hasResetPort(blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isfield(blk, 'Content')
        fields = fieldnames(blk.Content);
        fields = ...
            fields(...
            cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
        resetPortsFields = fields(...
            cellfun(@(x) strcmp(blk.Content.(x).BlockType,'ResetPort'), fields));
        b = ~isempty(resetPortsFields);
    else
        b = false;
    end
    
    if b
        ResetType = blk.Content.(resetPortsFields{1}).ResetTriggerType;
    else
        ResetType = '';
    end
end
