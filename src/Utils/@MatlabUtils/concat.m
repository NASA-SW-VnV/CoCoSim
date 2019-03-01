%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% concatenate 1-D vectors
function r = concat(varargin)
    if numel(varargin) == 1
        r = varargin{1};
        return;
    elseif numel(varargin) > 2
        v1 = varargin{1};
        v2 = MatlabUtils.concat(varargin{2:end});
    elseif numel(varargin) == 2
        v1 = varargin{1};
        v2 = varargin{2};
    end
    if isempty(v1)
        r = v2;
        return;
    elseif isempty(v2)
        r = v1;
        return;
    end
    [n1, ~] = size(v1);
    [n2, ~] = size(v2);
    if n1 == 1
        if n2 == 1
            r = [v1, v2];
        else
            r = [v1, v2'];
        end
    else
        if n2 == 1
            r = [v1; v2'];
        else
            r = [v1; v2];
        end
    end
end
