
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obj = contractNode_substituteVars(obj)
    if length(obj.bodyEqs) > 2500
        %Ignore optimization for Big Nodes (Like Lookup Table)
        display_msg(sprintf('Optimization ignored for node "%s" as the number of equations exceeds 2500 Eqs.\n',...
            obj.getName()), MsgType.INFO, 'contractNode_substituteVars', '');
        return;
    end

    localVars = obj.localVars;
    if isempty(localVars)
        return;
    end
    varsNames = cellfun(@(x) x.getId(), localVars, 'UniformOutput', false);
    varsDT = cellfun(@(x) x.getDT(), localVars, 'un', 0);
    varsMap = containers.Map(varsNames, localVars);
    
    
    % clock variables are ignored in optimization due to lustrec
    % limitations
    clockVars = localVars(coco_nasa_utils.MatlabUtils.contains(varsDT, 'clock'));
    clockVarIDs = cellfun(@(x) x.getId(), clockVars, 'UniformOutput', false);
    % include ConcurrentAssignments as normal Eqts
    bodyEqs = {};
    for i=1:numel(obj.bodyEqs)
        if isa(obj.bodyEqs{i}, 'nasa_toLustre.lustreAst.ConcurrentAssignments')
            bodyEqs = coco_nasa_utils.MatlabUtils.concat(bodyEqs, ...
                obj.bodyEqs{i}.getAssignments());
        elseif ~isempty(obj.bodyEqs{i})
            bodyEqs{end+1} = obj.bodyEqs{i};
        end
    end
    
    % creat a map of variables and equations refering them
    % The key is the name of the variable, the value is the indices of
    % equations refering to it in their right hand side.
    varToEqMap = containers.Map();
    try
        for i=1:numel(bodyEqs)
            if isa(bodyEqs{i}, 'nasa_toLustre.lustreAst.LustreAutomaton')
                %ignore simplification if there is automaton
                display_msg(sprintf('Optimization ignored for node "%d". It contains an automaton.',...
                    obj.getName()), MsgType.INFO, 'contractNode_substituteVars', '');
                return;
            end
            allLusObj = bodyEqs{i}.getAllLustreExpr();
            allLusObjClass = cellfun(@(x) class(x), allLusObj,...
                'UniformOutput', false);
            VarIdExprObjects = allLusObj(strcmp(allLusObjClass,...
                'nasa_toLustre.lustreAst.VarIdExpr'));
            varIDs = unique(cellfun(@(x) x.getId(), ...
                VarIdExprObjects, 'UniformOutput', false));
            for j = 1:length(varIDs)
                if isKey(varToEqMap, varIDs{j})
                    varToEqMap(varIDs{j}) = [varToEqMap(varIDs{j}), i];
                else
                    varToEqMap(varIDs{j}) = [i];
                end
            end
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'contractNode_substituteVars', '');
        display_msg(sprintf('Optimization ignored for node "%d".',...
            obj.getName()), MsgType.INFO, 'contractNode_substituteVars', '');
        return;
    end
    
    
    % go over Assignments
    for i=1:numel(bodyEqs)
        if ~( isa(bodyEqs{i}, 'nasa_toLustre.lustreAst.LustreEq')...
                && isa(bodyEqs{i}.getLhs(), 'nasa_toLustre.lustreAst.VarIdExpr')...
                && isKey(varsMap, bodyEqs{i}.getLhs().getId()) ...
                )
            continue
        end
        
        var = bodyEqs{i}.getLhs();
        lhsName = var.getId();
        rhs = bodyEqs{i}.getRhs();
        newVar = rhs; %rhs.deepCopy();
        
        % if rhs class is IteExpr, skip it. To help in debugging.
        if isa(rhs, 'nasa_toLustre.lustreAst.IteExpr')
            continue;
        end
        
        % Skip node calls for PRelude. e.g. y = f(x);
        % for traceability too and code readability.
        if isa(rhs, 'nasa_toLustre.lustreAst.NodeCallExpr')
            continue;
        end
        
        
        
        % if used on its definition, skip it
        %e.g. x = 0 -> pre x + 1;
        if rhs.nbOccuranceVar(var) >= 1
            continue;
        end
        
        if ~isKey(varToEqMap, lhsName) || length(varToEqMap(lhsName)) == 1
            continue;
        end
        
        % skip var if it is never used or used more than twice.
        % For code readability and CEX debugging.
        %nbOcc = length(varToEqMap(lhsName)) - 1;%minus itself
        %if ~(nbOcc == 1 || nbOcc == 2)
        %    continue;
        %end
        
        % skip var if it is used in EveryExpr/Merge/Activate condition. For Lustrec
        % limitation
        if ismember(lhsName, clockVarIDs)
            continue;
        end
        
        
        
        % change var by new_var
        newVarLusObj = newVar.getAllLustreExpr();
        newVarLusObjClass = cellfun(@(x) class(x), newVarLusObj,...
            'UniformOutput', false);
        newVarIdExprObjects = newVarLusObj(strcmp(newVarLusObjClass,...
            'nasa_toLustre.lustreAst.VarIdExpr'));
        newVarIDs = unique(cellfun(@(x) x.getId(), ...
            newVarIdExprObjects, 'UniformOutput', false));
        eqsIndices = unique(varToEqMap(lhsName));
        for k = eqsIndices
            if k == i || isa(bodyEqs{k}, 'nasa_toLustre.lustreAst.DummyExpr')
                continue
            end
            bodyEqs{k} = bodyEqs{k}.substituteVars(var, newVar);
            for j = 1:length(newVarIDs)
                if isKey(varToEqMap, newVarIDs{j})
                    varToEqMap(newVarIDs{j}) = [varToEqMap(newVarIDs{j}), k];
                else
                    varToEqMap(newVarIDs{j}) = k;
                end
            end
        end
        %bodyEqs = cellfun(@(x) x.substituteVars(var, new_var), bodyEqs, 'UniformOutput', false);
        
        %delete the current Eqts
        bodyEqs{i} = nasa_toLustre.lustreAst.DummyExpr();
        
        %remove it from variables
        varsMap.remove(lhsName);
        
    end
    % remove dummyExpr
    eqsClass = cellfun(@(x) class(x), bodyEqs, 'UniformOutput', false);
    bodyEqs = bodyEqs(~strcmp(eqsClass, 'nasa_toLustre.lustreAst.DummyExpr'));
    obj.setBodyEqs(bodyEqs);
    obj.setLocalVars(varsMap.values());
end
