classdef ContractAssumeExpr < nasa_toLustre.lustreAst.LustreExpr
    %ContractAssumeExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        id; %String
        exp; %LustreExp
    end
    
    methods
        function obj = ContractAssumeExpr(id, exp)
            obj.id = id;
            if iscell(exp)
                obj.exp = exp{1};
            else
                obj.exp = exp;
            end
        end
        
        %% deepcopy
        new_obj = deepCopy(obj)
        
        %% simplify expression
        new_obj = simplify(obj)

        %% nbOcc
        nb_occ = nbOccuranceVar(obj, var)

        %% substituteVars 
        new_obj = substituteVars(obj, oldVar, newVar)

        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.exp}; obj.exp.getAllLustreExpr()];
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)

        new_obj = changeArrowExp(obj, ~)
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.exp);
        end
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
       
        %%
        code = print(obj, backend)
       
        code = print_lustrec(obj)

        code = print_kind2(obj, backend)

        code = print_zustre(obj)

        code = print_jkind(obj)

        code = print_prelude(obj)

    end
    
end

