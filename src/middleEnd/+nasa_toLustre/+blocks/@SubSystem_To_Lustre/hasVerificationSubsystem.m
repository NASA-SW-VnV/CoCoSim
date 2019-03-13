function [b, hasNoOutputs, vsBlk] = hasVerificationSubsystem(blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
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
