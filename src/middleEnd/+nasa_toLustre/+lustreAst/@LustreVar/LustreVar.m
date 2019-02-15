classdef LustreVar < nasa_toLustre.lustreAst.LustreExpr
    %LustreVar
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name;%String
        type;%String
    end
    
    methods
        function obj = LustreVar(name, type)
            if isa(name, 'nasa_toLustre.lustreAst.VarIdExpr')
                obj.name = name.getId();
            elseif iscell(name) && numel(name) == 1
                obj.name = name{1};
            else
                obj.name = name;
            end
            if iscell(type) && numel(type) == 1
                obj.type = type{1};
            else
                obj.type = type;
            end
        end
        
        %%
        function id = getId(obj)
            id = obj.name;
        end
        function dt = getDT(obj)
            dt = obj.type;
        end
        
        
        new_obj = deepCopy(obj)
        
        %% simplify expression
        new_obj = simplify(obj)
        
        %% nbOccuranceVar
        nb_occ = nbOccuranceVar(~, ~)
        
         %% substituteVars
        new_obj = substituteVars(obj, varargin)
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        
        new_obj = changeArrowExp(obj, ~)
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {obj.name};
        end
        % this function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
        end
        
        
        
        %%
        code = print(obj, backend)
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    methods(Static)
        U = uniqueVars(vars)
        U = removeVar(vars, v)
        
        U = setDiff(s1, s2)
    end
end

