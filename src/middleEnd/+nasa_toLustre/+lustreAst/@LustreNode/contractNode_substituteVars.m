%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function new_obj = contractNode_substituteVars(obj)
   import nasa_toLustre.lustreAst.*
    new_obj = obj.deepCopy();
    new_localVars = new_obj.localVars;
    outputs = new_obj.getOutputs();
    % include ConcurrentAssignments as normal Eqts
    new_bodyEqs = {};
    for i=1:numel(new_obj.bodyEqs)
        if isa(new_obj.bodyEqs{i}, 'ConcurrentAssignments')
            new_bodyEqs = MatlabUtils.concat(new_bodyEqs, ...
                new_obj.bodyEqs{i}.getAssignments());
        else
            new_bodyEqs{end+1} = new_obj.bodyEqs{i};
        end
    end
    %ignore simplification if there is automaton
    all_obj = obj.getAllLustreExpr();
    all_objClass = cellfun(@(x) class(x), all_obj, 'UniformOutput', false);
    if ismember('nasa_toLustre.lustreAst.LustreAutomaton', all_objClass)
        return;
    end
    %get EveryExpr Conditions
    EveryExprObjects = all_obj(strcmp(all_objClass, 'nasa_toLustre.lustreAst.EveryExpr'));
    EveryConds = cellfun(@(x) x.getCond(), EveryExprObjects, 'UniformOutput', false);


    % go over Assignments
    for i=1:numel(new_bodyEqs)
        % e.g. y = f(x); 
        if isa(new_bodyEqs{i}, 'LustreEq')...
                && isa(new_bodyEqs{i}.getLhs(), 'VarIdExpr')...
                && VarIdExpr.ismemberVar(new_bodyEqs{i}.getLhs(), new_localVars)
            var = new_bodyEqs{i}.getLhs();
            rhs = new_bodyEqs{i}.getRhs();
            new_var = ParenthesesExpr(rhs.deepCopy());

            % if rhs class is IteExpr, skip it. To hep debugging.
            if isa(rhs, 'IteExpr')
                continue;
            end
            % if used on its definition, skip it
            %e.g. x = 0 -> pre x + 1;
            if rhs.nbOccuranceVar(var) >= 1
                continue;
            end
            nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), new_bodyEqs, 'UniformOutput', true);
            % skip var if it is never used or used more than once. 
            % For code readability and CEX debugging.
            nb_occ = sum(nb_occ_perEq);
            if nb_occ > 1
                continue;
            end

            % check the variable is not used in EveryExpr condition.
            nb_occ_perEveryCond = cellfun(@(x) x.nbOccuranceVar(var), EveryConds, 'UniformOutput', true);
            if ~isempty(nb_occ_perEveryCond) && sum(nb_occ_perEveryCond) >= 1
                continue;
            end


            %delete the current Eqts
            new_bodyEqs{i} = DummyExpr();
            %remove it from variables
            new_localVars = LustreVar.removeVar(new_localVars, var);
            % change var by new_var
            new_bodyEqs = cellfun(@(x) x.substituteVars(var, new_var), new_bodyEqs, 'UniformOutput', false);
        end
    end
    % remove dummyExpr
    eqsClass = cellfun(@(x) class(x), new_bodyEqs, 'UniformOutput', false);
    new_bodyEqs = new_bodyEqs(~strcmp(eqsClass, 'nasa_toLustre.lustreAst.DummyExpr'));
    new_obj.setBodyEqs(new_bodyEqs);
    new_obj.setLocalVars(new_localVars);
end 
