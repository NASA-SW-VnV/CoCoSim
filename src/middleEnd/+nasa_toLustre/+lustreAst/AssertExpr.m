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
        
        function new_obj = deepCopy(obj)
            new_obj = nasa_toLustre.lustreAst.AssertExpr(obj.exp.deepCopy());
        end
        
        %% simplify expression
        function new_obj = simplify(obj)
            new_obj = nasa_toLustre.lustreAst.AssertExpr(obj.exp.simplify());
        end
        %% nbOcc
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ = obj.exp.nbOccuranceVar(var);
        end
        %% substituteVars
        function new_obj = substituteVars(obj, oldVar, newVar)
            new_obj = nasa_toLustre.lustreAst.AssertExpr(...
                obj.exp.substituteVars(oldVar, newVar));
        end
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.exp}; obj.exp.getAllLustreExpr()];
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        function new_obj = changeArrowExp(obj, cond)
            new_obj = nasa_toLustre.lustreAst.AssertExpr(obj.exp.changeArrowExp(cond));
        end
        
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = obj.exp.GetVarIds();
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            [new_exp, outputs_map] = obj.exp.pseudoCode2Lustre(outputs_map, isLeft);
            new_obj = nasa_toLustre.lustreAst.AssertExpr(new_exp);
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = obj.exp.getNodesCalled();
        end
        
        
        
        %%
        function code = print(obj, backend)
            %TODO: check if KIND2 syntax is OK for the other backends.
            code = obj.print_kind2(backend);
        end
        
        
        function code = print_lustrec(obj, backend)
            code = obj.print_kind2(backend);
        end
        function code = print_kind2(obj, backend)
            
            code = sprintf('assert %s;', ...
                obj.exp.print(backend));
            
        end
        function code = print_zustre(obj, backend)
            code = obj.print_kind2(backend);
        end
        function code = print_jkind(obj, backend)
            code = obj.print_kind2(backend);
        end
        function code = print_prelude(varargin)
            code = '';
        end
    end
    
end

