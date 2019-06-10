
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Substates objects
function subStates = getSubStatesObjects(state)
    global SF_STATES_PATH_MAP;
    childrenNames = state.Composition.Substates;
    subStates = cell(numel(childrenNames), 1);
    for i=1:numel(childrenNames)
        childPath = fullfile(state.Path, childrenNames{i});
        if ~isKey(SF_STATES_PATH_MAP, childPath)
            ME = MException('COCOSIM:STATEFLOW', ...
                'COMPILER ERROR: Not found state "%s" in SF_STATES_PATH_MAP', childPath);
            throw(ME);
        end
        subStates{i} = SF_STATES_PATH_MAP(childPath);
    end
end
