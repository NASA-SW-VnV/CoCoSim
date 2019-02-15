classdef LustreEq < nasa_toLustre.lustreAst.LustreExpr
    %LustreEq
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        lhs;
        rhs;
    end
    
    methods
        function obj = LustreEq(lhs, rhs)
            if ischar(rhs)
                obj.rhs = nasa_toLustre.lustreAst.VarIdExpr(rhs);
            elseif iscell(rhs) && numel(rhs) == 1
                obj.rhs = rhs{1};
            elseif iscell(rhs)
                obj.rhs = nasa_toLustre.lustreAst.TupleExpr(rhs);
            else
                obj.rhs = rhs;
            end
            if ischar(lhs)
                obj.lhs = nasa_toLustre.lustreAst.VarIdExpr(lhs);
            elseif iscell(lhs) && numel(lhs) == 1
                obj.lhs = lhs{1};
            elseif iscell(lhs)
                obj.lhs = nasa_toLustre.lustreAst.TupleExpr(lhs);
            else
                obj.lhs = lhs;
            end
        end
        function lhs = getLhs(obj)
            lhs = obj.lhs;
        end
        function rhs = getRhs(obj)
            rhs = obj.rhs;
        end
        %%
        function new_obj = deepCopy(obj)
            new_lhs = obj.lhs.deepCopy();
            new_rhs = obj.rhs.deepCopy();
            new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
        end
        
        %% simplify expression
        function new_obj = simplify(obj)
            new_lhs = obj.lhs.simplify();
            new_rhs = obj.rhs.simplify();
            new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
        end
        
        %% nbOcc
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ = obj.rhs.nbOccuranceVar(var);
        end
        %% substituteVars
        function new_obj = substituteVars(obj, oldVar, newVar)
            new_lhs = obj.lhs.substituteVars(oldVar, newVar);
            new_rhs = obj.rhs.substituteVars(oldVar, newVar);
            new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
        end
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.lhs}; {obj.rhs}; obj.lhs.getAllLustreExpr();...
                obj.rhs.getAllLustreExpr()];
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            [new_lhs, VarIdlhs] = obj.lhs.changePre2Var();
            varIds = [varIds, VarIdlhs];
            
            [new_rhs, VarIdrhs] = obj.rhs.changePre2Var();
            varIds = [varIds, VarIdrhs];
            
            new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
        end
        
        function new_obj = changeArrowExp(obj, cond)
            new_rhs = obj.rhs.changeArrowExp(cond);
            new_obj = nasa_toLustre.lustreAst.LustreEq(obj.lhs, new_rhs);
        end
        
        %% Stateflow function
        function [outputs, inputs] = GetVarIds(obj)
            outputs = obj.lhs.GetVarIds();
            inputs = obj.rhs.GetVarIds();
        end
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            new_rhs = obj.rhs.pseudoCode2Lustre(outputs_map, false);
            [new_lhs, outputs_map] = obj.lhs.pseudoCode2Lustre(outputs_map, true);
            new_obj = nasa_toLustre.lustreAst.LustreEq(new_lhs, new_rhs);
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.rhs);
        end
        
        
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        
        function code = print_lustrec(obj, backend)
%             try
            lhs_str = obj.lhs.print(backend);
            rhs_str = obj.rhs.print(backend);
            code = sprintf('%s = %s;', lhs_str, rhs_str);
%             catch me
%                 me
%             end
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(LusBackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(LusBackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(LusBackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(LusBackendType.PRELUDE);
        end
    end
    
end

