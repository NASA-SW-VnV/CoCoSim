classdef LusBackendType < handle
    %Backend Types
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant)
        % Lustre backends
        LUSTREC = 'LUSTREC';
        KIND2 = 'KIND2';
        ZUSTRE = 'ZUSTRE';
        JKIND = 'JKIND';
        PRELUDE = 'PRELUDE';
    end
    
    methods(Static)
        res = isLUSTREC(b)

        res = isKIND2(b)

        res = isZUSTRE(b)

        res = isJKIND(b)

        res = isPRELUDE(b)

    end
end
