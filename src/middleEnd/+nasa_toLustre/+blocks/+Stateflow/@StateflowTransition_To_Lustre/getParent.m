
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function parent = getParent(child)
    global SF_STATES_PATH_MAP;
    if isfield(child, 'Path')
        childPath = child.Path;
    else
        %in destination struct, Name refers to Path. IR problem
        childPath = child.Name;
    end
    parent = SF_STATES_PATH_MAP(fileparts(childPath));
end
