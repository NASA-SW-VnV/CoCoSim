
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
%getTransitionsNode
function [transitionNode, external_libraries] = ...
        getTransitionsNode(T, data_map, parentPath, ...
        isDefaultTrans, ...
        node_name, comment, isFlowChartJunction)
    global SF_STATES_NODESAST_MAP CoCoSimPreferences;
    
    transitionNode = {};
    external_libraries = {};
    
    if ~exist('isFlowChartJunction', 'var')
        isFlowChartJunction = false;
    end
    if isempty(parentPath)
        %main chart
        return;
    end
    if isempty(T)
        return;
    end
    transitionNode = nasa_toLustre.lustreAst.LustreNode();
    transitionNode.setName(node_name);
    transitionNode.setMetaInfo(comment);
    %is_imported  = false;
    % create body
%     try
        [body, outputs, inputs, variables, external_libraries, ...
            ~, ~, hasJunctionLoop] = ...
            nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.transitions_code(T, data_map, ...
            isDefaultTrans, isFlowChartJunction, parentPath, {}, {}, {}, {}, {});
%     catch me
%         % Junctions Loop detection
%         if strcmp(me.identifier, 'COCOSIM:SF:JUNCTIONS_LOOP')
%             display_msg(me.message, MsgType.ERROR,...
%                 'getTransitionsNode', '');
%         else
%             display_msg(me.getReport(), MsgType.DEBUG, ...
%                 'getTransitionsNode', '');
%         end
%         if CoCoSimPreferences.abstract_unsupported_blocks
%             is_imported = true;
%             transitionNode.setIsImported(true);
%             outputs = {};
%             inputs = {};
%             body = {};
%             variables = {};
%             external_libraries = {};
%         else
%             return
%         end
%     end
    if hasJunctionLoop ...
            && CoCoSimPreferences.abstract_unsupported_blocks
        transitionNode.setIsImported(true);
    end
         
    if isempty(outputs)
        transitionNode = {};
        return;
    end

    % creat node
    
    
    outputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(outputs);
    inputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(inputs);
    
    % Handle Termination condition variable
    termVarName = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTerminationCondName();
    if ~isFlowChartJunction
        % remove Termination condition for Stateflow flow charts
        if nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(termVarName, outputs)
            outputs = nasa_toLustre.lustreAst.LustreVar.removeVar(outputs, termVarName);
            variables{end+1} = nasa_toLustre.lustreAst.LustreVar(termVarName, 'bool');
        end
    end
    if nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(termVarName, inputs)
        inputs = nasa_toLustre.lustreAst.LustreVar.removeVar(inputs, termVarName);
        if ~isFlowChartJunction
            variables{end+1} = nasa_toLustre.lustreAst.LustreVar(termVarName, 'bool');
        end
        % add as first equation termCond = False;
        body = coco_nasa_utils.MatlabUtils.concat(...
            {nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.VarIdExpr(termVarName), ...
            nasa_toLustre.lustreAst.BoolExpr(false))},...
            body);
    end
    
    variables = nasa_toLustre.lustreAst.LustreVar.uniqueVars(variables);
    if isempty(inputs)
        inputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = nasa_toLustre.lustreAst.LustreVar.removeVar(inputs, nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr());
    end
    transitionNode.setBodyEqs(body);
    transitionNode.setOutputs(outputs);
    transitionNode.setInputs(inputs);
    transitionNode.setLocalVars(variables);
    SF_STATES_NODESAST_MAP(node_name) = transitionNode;
end
