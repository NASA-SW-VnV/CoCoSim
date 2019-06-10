
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Transition code
function [body, outputs, inputs, variables, external_libraries, ...
        validDestination_cond, Termination_cond] = ...
        transitions_code(transitions, data_map, isDefaultTrans, parentPath, ...
        validDestination_cond, Termination_cond, cond_prefix, fullPathT, variables)
    
    body = {};
    outputs = {};
    inputs = {};
    external_libraries = {};
    n = numel(transitions);
    for i=1:n
        t_list = [fullPathT, transitions(i)];
        [body_i, outputs_i, inputs_i, variables, external_libraries_i, ...
            validDestination_cond, Termination_cond] = ...
            nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.evaluate_Transition(...
            transitions{i}, data_map, isDefaultTrans, parentPath, ...
            validDestination_cond, Termination_cond, ...
            cond_prefix, t_list, variables);
        body = [ body , body_i ];
        outputs = [ outputs , outputs_i ] ;
        inputs = [ inputs , inputs_i ] ;
        external_libraries = [external_libraries , external_libraries_i];
    end
end
