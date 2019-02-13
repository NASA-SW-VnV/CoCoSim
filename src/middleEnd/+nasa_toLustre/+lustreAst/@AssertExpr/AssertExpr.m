classdef AssertExpr < nasa_toLustre.lustreAst.LustreExpr
    %AssertExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        exp; %LustreExp
    end
    
    methods
        
        function obj = AssertExpr(exp)
            if iscell(exp)
                obj.exp = exp{1};
            else
                obj.exp = exp;
            end
        end
        
        new_obj = deepCopy(obj)
        
        %% simplify expression
        new_obj = simplify(obj)
            
        %% nbOcc
        nb_occ = nbOccuranceVar(obj, var)
            
        %% substituteVars
        new_obj = substituteVars(obj, oldVar, newVar)
            
        all_obj = getAllLustreExpr(obj)
            
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)

        new_obj = changeArrowExp(obj, cond)
        
        %% This is used by Stateflow SF_To_LustreNode.getPseudoLusAction
        varIds = GetVarIds(obj)

        % This is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)

        %% This is used by KIND2 LustreProgram.print()
        nodesCalled = getNodesCalled(obj)

        %%
        code = print(obj, backend)
 
        code = print_lustrec(obj, backend)

        code = print_kind2(obj, backend)

        code = print_zustre(obj, backend)

        code = print_jkind(obj, backend)

        code = print_prelude(varargin)

    end
    
end

