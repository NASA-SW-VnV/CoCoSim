
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Utils functions
function full_path_trace = get_full_path_trace(transitions, isDefaultTrans)
    %L = nasa_toLustre.ToLustreImport.L;
    %import(L{:})
    transition_name = cell(numel(transitions), 1);
    for i=1:numel(transitions)
        transition = transitions{i};
        if isDefaultTrans && i==1
            transition_name{i} = 'Default_Transition';
        else
            transition_name{i} = ...
                nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getUniqueName(transition, transition.Source);
        end
    end
    full_path_trace = MatlabUtils.strjoin(transition_name,', ');
end

