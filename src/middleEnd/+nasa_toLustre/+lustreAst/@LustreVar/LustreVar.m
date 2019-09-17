classdef LustreVar < nasa_toLustre.lustreAst.LustreExpr
    %LustreVar
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        id;%String
        type;%String
        rate; %for Prelude
    end
    
    methods
        function obj = LustreVar(id, type, rate)
            if isa(id, 'nasa_toLustre.lustreAst.VarIdExpr')
                obj.id = id.getId();
            elseif iscell(id) && numel(id) == 1
                obj.id = id{1};
            else
                obj.id = id;
            end
            if iscell(type) && numel(type) == 1
                obj.type = type{1};
            else
                obj.type = type;
            end
            if nargin < 3
                obj.rate = '';
            else
                obj.rate = rate;
            end
        end
        
        %%
        function id = getId(obj)
            id = obj.id;
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
            varIds = {obj.id};
        end
        % this function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
        
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

