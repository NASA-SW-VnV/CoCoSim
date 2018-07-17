classdef BackendType < handle
    %Backend Types
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant)
        LUSTREC = 'LUSTREC';
        KIND2 = 'KIND2';
        ZUSTRE = 'ZUSTRE';
        JKIND = 'JKIND';
        PRELUDE = 'PRELUDE';
    end
    
    methods(Static)
        function res = isLUSTREC(b)
            res = isequal(b, BackendType.LUSTREC);
        end
        function res = isKIND2(b)
            res = isequal(b, BackendType.KIND2);
        end
        function res = isZUSTRE(b)
            res = isequal(b, BackendType.ZUSTRE);
        end
        function res = isJKIND(b)
            res = isequal(b, BackendType.JKIND);
        end
        function res = isPRELUDE(b)
            res = isequal(b, BackendType.PRELUDE);
        end
    end
end
