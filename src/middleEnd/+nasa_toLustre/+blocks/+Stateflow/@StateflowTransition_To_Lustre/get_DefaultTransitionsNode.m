
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
%get_DefaultTransitionsNode
function [transitionNode, external_nodes, external_libraries] = ...
        get_DefaultTransitionsNode(state, data_map)
    
    external_nodes = {};
    external_libraries = {};
    parentPath = state.Path;
    T = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
        state.Composition.DefaultTransitions, 'ExecutionOrder');
    isDefaultTrans = true;
    %% Add Junctions that has no state as destination to external nodes. The
    % junction node will perform the conditions actions.
    junctions_map = containers.Map();
    junctions_with_no_state_destination(T, junctions_map);
    if ~isempty(junctions_map)
        visited = containers.Map();
        [external_nodes, external_libraries] = get_JuncOuterTransitionsNode(...
        T, data_map, junctions_map, visited);
    end
    
    %% Default Transition node
    node_name = ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateDefaultTransNodeName(state);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Default transitions of state %s', state.Origin_path), true);
    [transitionNode, external_libraries_i] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTransitionsNode(T, data_map, parentPath, ...
        isDefaultTrans, ...
        node_name, comment);
    external_libraries = [external_libraries, external_libraries_i];
end

%%
function [external_nodes, external_libraries] = get_JuncOuterTransitionsNode(...
        T, data_map, junctions_map, visited)
    global SF_JUNCTIONS_PATH_MAP
    external_libraries = {};
    external_nodes = {};
    n = length(T);
    for i = 1:n
        t = T{i};
        destination = t.Destination;
        if strcmp(destination.Type,'Junction')
            if isKey(visited, destination.Name)
                continue;
            else
                visited(destination.Name) = destination;
            end
            if ~isKey(SF_JUNCTIONS_PATH_MAP, destination.Name)
                continue;
            end
            % add connected junctions nodes first.
            hobject = SF_JUNCTIONS_PATH_MAP(destination.Name);
            
            transitions2 = ...
                nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
                hobject.OuterTransitions, 'ExecutionOrder');
            
            [external_nodes_i, external_libraries_i] = ...
                get_JuncOuterTransitionsNode(transitions2, data_map, ...
                junctions_map, visited);
            
            external_libraries = [external_libraries, external_libraries_i];
            external_nodes = [external_nodes, external_nodes_i];
            
            % add this junction code
            if isKey(junctions_map, destination.Name)
                if length(transitions2) <= 1
                    % to avoid junctions with one transition
                    continue
                end
                [node,  external_libraries_i] = ...
                    nasa_toLustre.blocks.Stateflow.StateflowJunction_To_Lustre.get_OuterTransitionsNode(...
                    hobject, data_map);
                if ~isempty(node)
                    external_nodes{end+1} = node;
                end
                external_libraries = [external_libraries, external_libraries_i];
            end
            
        end
    end
end
%%
function [res] = junctions_with_no_state_destination(transitions, junctions_map)
    global SF_JUNCTIONS_PATH_MAP
    res = true;
    if isempty(transitions)
        return
    end
    n = length(transitions);
    for i = 1:n
        t = transitions{i};
        destination = t.Destination;
        if strcmp(destination.Type,'Junction')
            %the destination is a junction
            if isKey(junctions_map, destination.Name)
                continue;
            end
            if isKey(SF_JUNCTIONS_PATH_MAP, destination.Name)
                hobject = SF_JUNCTIONS_PATH_MAP(destination.Name);
                if strcmp(hobject.Type, 'HISTORY')
                    res = false;
                    return
                else
                    %Does the junction have any outgoing transitions?
                    transitions2 = ...
                        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
                        hobject.OuterTransitions, 'ExecutionOrder');
                    [res_i] = junctions_with_no_state_destination(transitions2, junctions_map);
                    if res_i
                        junctions_map(destination.Name) = hobject;
                    else
                        res = false;
                        return;
                    end
                end
            end
        else
            res = false;
            return
        end
        
    end
end