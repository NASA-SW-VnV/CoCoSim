classdef CoCoBackendType < handle
    %Backend Types
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant)
        % CoCoSim Backends
        COMPATIBILITY = 'COMPATIBILITY';
        VERIFICATION = 'Verification';
        VALIDATION = 'Validation';
        PP_VALIDATION = 'PP_Validation';
        GUIDELINES = 'GUIDELINES';
        DED = 'DesignErrorDetection';
        DED_INTOVERFLOW = 'Integer Overflow';
        DED_DIVBYZER = 'Division By Zero';
        DED_OUTMINMAX = 'Check OutMin OutMax';
        DED_OUTOFBOUND = 'Out of Bound Array Access';
    end
    
    methods(Static)
        res = isCOMPATIBILITY(b)

        res = isVERIFICATION(b)

        res = isVALIDATION(b)
        
        res = isPPVALIDATION(b)

        res = isGUIDELINES(b)

        res = isDED(b)

    end
end
