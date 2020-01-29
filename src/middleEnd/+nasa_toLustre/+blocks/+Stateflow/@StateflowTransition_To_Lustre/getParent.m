
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

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
