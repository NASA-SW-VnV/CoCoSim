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
        GUIDELINES = 'GUIDELINES';
        DED = 'DesignErrorDetection';
        DED_INTOVERFLOW = 'Integer Overflow';
        DED_DIVBYZER = 'Division By Zero';
        DED_OUTMINMAX = 'Check OutMin OutMax';
        DED_OUTOFBOUND = 'Out of Bound Array Access';
    end
    
    methods(Static)
        function res = isCOMPATIBILITY(b)
            res = isequal(b, CoCoBackendType.COMPATIBILITY);
        end
        function res = isVERIFICATION(b)
            res = isequal(b, CoCoBackendType.VERIFICATION);
        end
        function res = isVALIDATION(b)
            res = isequal(b, CoCoBackendType.VALIDATION);
        end
        function res = isGUIDELINES(b)
            res = isequal(b, CoCoBackendType.GUIDELINES);
        end
        function res = isDED(b)
            res = isequal(b, CoCoBackendType.DED);
        end
    end
end
