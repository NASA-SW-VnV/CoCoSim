classdef DEDUtils
    %DEDUTILS DesignErrorDetection(DED) utils functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods(Static)
        OutOfBoundCheckCode(blk2LusObj, parent, blk, xml_trace, indexPortNames, width, isZeroBased, propID, propIndex)
        OutMinMaxCheckCode(blk2LusObj, parent, blk, outputs, lus_dt, xml_trace, addAsAssertExpr)
    end
end

