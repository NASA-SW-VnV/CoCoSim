function ep = calculate_eps(BP, j)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isnumeric(BP)
        ep = [];
        return;
    end
    fraction = 1e6;
    if length(BP) == 1
        ep = eps(double(BP));
    elseif j == 1
        ep = abs(BP(2) - BP(1)) / fraction;
    elseif j == numel(BP)
        ep = abs(BP(j-1) - BP(j)) / fraction;
    else
        ep = min(abs(BP(j-1) - BP(j)), abs(BP(j+1) - BP(j))) / fraction;
    end
end
