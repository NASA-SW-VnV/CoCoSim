%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function mkdir(path)
    tokens = regexp(path, filesep, 'split');
    for i=2:numel(tokens)
        d = MatlabUtils.strjoin(tokens(1:i), filesep);
        if ~exist(d, 'dir')
            mkdir(d);
        end
    end
end
