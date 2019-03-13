%StateflowTruthTable_To_Lustre: transform Table to graphical function.
% Then use StateflowGraphicalFunction_To_Lustre
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function transitionStruct = buildTransitionStruct(ExecutionOrder, destination, C, CAction, srcPath)
    transitionStruct = {};
    transitionStruct.Id = nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.incrementID();
    transitionStruct.ExecutionOrder = ExecutionOrder;
    transitionStruct.Destination.Id = destination.Id;
    transitionStruct.Source = srcPath;
    % parse the label string of the transition
    transitionStruct.Event ='';
    transitionStruct.Condition = C;
    transitionStruct.ConditionAction = CAction;
    transitionStruct.TransitionAction = '';
    %keep LabelString in case the parser failed.
    transitionStruct.LabelString = sprintf('[%s]{%s}', C, CAction);
    transitionStruct.Destination.Type = 'Junction';
    transitionStruct.Destination.Name = destination.Path;
    transitionStruct.Destination.Origin_path = destination.Origin_path;
end


