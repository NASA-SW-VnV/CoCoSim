classdef RealExpr < nasa_toLustre.lustreAst.LustreExpr
    %RealExpr

    properties
        value;
    end
    
    methods
        function obj = RealExpr(v)
            obj.value = v;
        end
        %%
        function v = getValue(obj)
            if isnumeric(obj.value) || islogical(obj.value)
                v =  obj.value;
            elseif ischar(obj.value)
                v = str2double(obj.value);
            else
                display_msg(sprintf('%s is not a lustre Real Expression', obj.value), ...
                    MsgType.ERROR, 'RealExpr', '');
                v = obj.value;
            end
        end
        %%
        new_obj = deepCopy(obj)
        %% simplify expression
        new_obj = simplify(obj)
        %% nbOccuranceVar
        nb_occ = nbOccuranceVar(varargin)
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
        function varIds = GetVarIds(~)
            varIds = {};
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, varargin)
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(~)
            nodesCalled = {};
        end
        
        
        
        %%
        code = print(obj, ~)
        
        code = print_lustrec(obj)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    
end

