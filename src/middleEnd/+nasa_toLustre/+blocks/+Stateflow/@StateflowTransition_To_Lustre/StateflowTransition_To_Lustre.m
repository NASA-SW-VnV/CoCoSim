%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef StateflowTransition_To_Lustre
    %StateflowTransition_To_Lustre

    
    properties
    end
    
    methods(Static)
        %%
        function options = getUnsupportedOptions(varargin)
            options = {};
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        %% Main functions
        [action_nodes, external_libraries ] = ...
                get_Actions(T, data_map, source_state, isDefaultTrans)
        
        %get_DefaultTransitionsNode
        [transitionNode, external_libraries] = ...
                get_DefaultTransitionsNode(state, data_map)
        
        %get_InnerTransitionsNode
        [transitionNode, external_libraries] = ...
                get_InnerTransitionsNode(state, data_map)

        %get_OuterTransitionsNode
        [transitionNode, external_libraries] = ...
                get_OuterTransitionsNode(state, data_map)

        %getTransitionsNode
        [transitionNode, external_libraries] = ...
                getTransitionsNode(T, data_map, parentPath, ...
                isDefaultTrans, ...
                node_name, comment)

        %% Condition and Transition Actions
         [main_node, external_nodes, external_libraries ] = ...
                write_ConditionAction(T, data_map, source_state, isDefaultTrans)
        
         [main_node, external_nodes, external_libraries ] = ...
                write_TransitionAction(T, data_map, source_state, isDefaultTrans)
        
         [main_node, external_nodes, external_libraries ] = ...
                write_Action(T, data_map, source_state, type, isDefaultTrans)
        
         [main_node, external_nodes, external_libraries ] = ...
                write_Action_Node(action, data_map, t_act_node_name, transitionPath)

        %% Transition code
        [body, outputs, inputs, variables, external_libraries, ...
                validDestination_cond, Termination_cond] = ...
                transitions_code(transitions, data_map, isDefaultTrans, parentPath, ...
                validDestination_cond, Termination_cond, cond_prefix, fullPathT, variables)

        [body, outputs, inputs, variables, external_libraries, validDestination_cond, Termination_cond] = ...
                evaluate_Transition(t, data_map, isDefaultTrans, parentPath, ...
                validDestination_cond, Termination_cond, cond_prefix, fullPathT, variables)
        
        [Termination_cond, body, outputs, variables] = ...
                updateTerminationCond(Termination_cond, condName, trans_cond, ...
                body, outputs, variables, addToVariables)
        
        %transition actions
        [body, outputs, inputs] = ...
                full_tran_trans_actions(transitions, trans_cond)

        %exit actions
        [body, outputs, inputs] = ...
                full_tran_exit_actions(transitions, parentPath, trans_cond)

        % Entry actions
        [body, outputs, inputs, antiCondition] = ...
                full_tran_entry_actions(transitions, parentPath, trans_cond, isHJ)

        %% Utils functions
        full_path_trace = get_full_path_trace(transitions, isDefaultTrans)
        
        is_parent = isParent(Parent,child)
        
        parent = getParent(child)

        %% Get unique short name
        unique_name = getTransName(object, src, isDefaultTrans)

        node_name = getCondActNewVarName(T)

        node_name = getCondActionNodeName(T, src, isDefaultTrans)

        node_name = getTranActionNodeName(T, src, isDefaultTrans)

        varName = getTerminationCondName()
 
        varName = getValidPathCondName()

    end
    
end

