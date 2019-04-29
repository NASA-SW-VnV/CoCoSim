classdef LookupType < handle
    % Lookup Table Types
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant)
        % Lustre backends
        Lookup_nD = 'Lookup_nD';
        LookupDynamic = 'LookupDynamic';
        PreLookup = 'PreLookup';
        Interpolation_nD = 'Interpolation_nD';
    end
    
    methods(Static)
        function res = isLookup_nD(b)
            res = strcmp(b, LookupType.Lookup_nD);
        end
        function res = isLookupDynamic(b)
            res = strcmp(b, LookupType.LookupDynamic);
        end
        function res = isPreLookup(b)
            res = strcmp(b, LookupType.PreLookup);
        end
        function res = isInterpolation_nD(b)
            res = strcmp(b, LookupType.Interpolation_nD);
        end
    end
end
