%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function obj = contractNode_substituteVars(obj)
    import nasa_toLustre.lustreAst.*
    if length(obj.bodyEqs) > 500
        %Ignore optimization for Big Nodes (Like Lookup Table)
        display_msg(sprintf('Optimization ignored for node "%d" as the number of equations exceeds 500 Eqs.',...
            obj.getName()), MsgType.INFO, 'contractNode_substituteVars', '');
        return;
    end
    new_localVars = obj.localVars;
    % include ConcurrentAssignments as normal Eqts
    new_bodyEqs = {};
    for i=1:numel(obj.bodyEqs)
        if isa(obj.bodyEqs{i}, 'ConcurrentAssignments')
            new_bodyEqs = MatlabUtils.concat(new_bodyEqs, ...
                obj.bodyEqs{i}.getAssignments());
        else
            new_bodyEqs{end+1} = obj.bodyEqs{i};
        end
    end
    %ignore simplification if there is automaton
    all_body_obj = cellfun(@(x) x.getAllLustreExpr(), new_bodyEqs, 'un',0);
    all_body_obj = MatlabUtils.concat(all_body_obj{:});
    all_objClass = cellfun(@(x) class(x), all_body_obj, 'UniformOutput', false);
    if ismember('nasa_toLustre.lustreAst.LustreAutomaton', all_objClass)
        return;
    end
    %get EveryExpr Conditions
    EveryExprObjects = all_body_obj(strcmp(all_objClass, 'nasa_toLustre.lustreAst.EveryExpr'));
    EveryConds = cellfun(@(x) x.getCond(), EveryExprObjects, 'UniformOutput', false);
    
    %get all VarIdExpr objects
    VarIdExprObjects = all_body_obj(strcmp(all_objClass, 'nasa_toLustre.lustreAst.VarIdExpr'));
    varIDs = cellfun(@(x) x.getId(), VarIdExprObjects, 'UniformOutput', false);
    % go over Assignments
    for i=1:numel(new_bodyEqs)
        % e.g. y = f(x);
        
        if isa(new_bodyEqs{i}, 'LustreEq')...
                && isa(new_bodyEqs{i}.getLhs(), 'VarIdExpr')...
                && nasa_toLustre.lustreAst.VarIdExpr.ismemberVar(new_bodyEqs{i}.getLhs(), new_localVars)
            var = new_bodyEqs{i}.getLhs();
            rhs = new_bodyEqs{i}.getRhs();
            new_var = nasa_toLustre.lustreAst.ParenthesesExpr(rhs.deepCopy());
            
            % if rhs class is IteExpr, skip it. To hep debugging.
            if isa(rhs, 'IteExpr')
                continue;
            end
            % if used on its definition, skip it
            %e.g. x = 0 -> pre x + 1;
            if rhs.nbOccuranceVar(var) >= 1
                continue;
            end
            % skip var if it is never used or used more than once.
            % For code readability and CEX debugging.
            nb_occ = sum(strcmp(var.getId(), varIDs)) - 1;%minus itself
            if nb_occ ~= 1
                continue;
            end
            
            % check the variable is not used in EveryExpr condition.
            nb_occ_perEveryCond = cellfun(@(x) x.nbOccuranceVar(var), EveryConds, 'UniformOutput', true);
            if ~isempty(nb_occ_perEveryCond) && sum(nb_occ_perEveryCond) >= 1
                continue;
            end
            
            
            %delete the current Eqts
            new_bodyEqs{i} = nasa_toLustre.lustreAst.DummyExpr();
            %remove it from variables
            new_localVars = nasa_toLustre.lustreAst.LustreVar.removeVar(new_localVars, var);
            % change var by new_var
            new_bodyEqs = cellfun(@(x) x.substituteVars(var, new_var), new_bodyEqs, 'UniformOutput', false);
        end
    end
    % remove dummyExpr
    eqsClass = cellfun(@(x) class(x), new_bodyEqs, 'UniformOutput', false);
    new_bodyEqs = new_bodyEqs(~strcmp(eqsClass, 'nasa_toLustre.lustreAst.DummyExpr'));
    obj.setBodyEqs(new_bodyEqs);
    obj.setLocalVars(new_localVars);
end
