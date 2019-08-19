function [b, Iteratorblk] = hasForIterator(blk)
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
        forIteratorFields = fields(...
            cellfun(@(x) strcmp(blk.Content.(x).BlockType,'ForIterator'), fields));
        b = ~isempty(forIteratorFields);
    else
        b = false;
    end
    
    if b
        Iteratorblk = blk.Content.(forIteratorFields{1});
    else
        Iteratorblk = [];
    end
end
