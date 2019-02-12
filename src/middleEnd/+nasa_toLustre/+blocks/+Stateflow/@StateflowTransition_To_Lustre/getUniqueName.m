
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Get unique short name
function unique_name = getUniqueName(object, src, isDefaultTrans)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if nargin < 2
        src = T.Source;
    end
    if nargin < 3
        if isempty(src)
            isDefaultTrans = true;
        else
            isDefaultTrans = false;
        end
    end
    dst = object.Destination;
    id_str = sprintf('%.0f', object.ExecutionOrder);
    if isDefaultTrans
        sourceName = '_DefaultTransition';
    else
        sourceName = SF2LusUtils.getUniqueName(src);
    end
    unique_name = sprintf('%s_To_%s_ExecutionOrder%s',...
        sourceName, ...
        SF2LusUtils.getUniqueName(dst), id_str );

end
