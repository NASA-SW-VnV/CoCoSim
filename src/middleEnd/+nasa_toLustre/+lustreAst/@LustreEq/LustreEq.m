classdef LustreEq < nasa_toLustre.lustreAst.LustreExpr
    %LustreEq
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
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
        new_obj = deepCopy(obj)
        
        %% simplify expression
        new_obj = simplify(obj)
        
        %% nbOcc
        nb_occ = nbOccuranceVar(obj, var)
        %% substituteVars
        new_obj = substituteVars(obj, oldVar, newVar)
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.lhs; obj.rhs}; obj.lhs.getAllLustreExpr();...
                obj.rhs.getAllLustreExpr()];
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        
        new_obj = changeArrowExp(obj, cond)
        
        %% Stateflow function
        function [outputs, inputs] = GetVarIds(obj)
            outputs = obj.lhs.GetVarIds();
            inputs = obj.rhs.GetVarIds();
        end
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.rhs);
        end
        
        
        %%
        code = print(obj, backend)
        
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    
end

