
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function b = isIgnoredSampleTime(st_n, ph_n)
    b = st_n <= 0 || ph_n < 0 || ...
        (...
        (st_n == 1 ||  isinf(st_n) || isnan(st_n))...
        && (ph_n == 0 || isinf(ph_n) || isnan(ph_n))...
        );
end
