classdef EnumValueExpr < nasa_toLustre.lustreAst.LustreExpr
    %EnumValueExpr: a member of Enumeration type. e.g. Monday in Days
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        enum_name;
    end
    
    methods
        function obj = EnumValueExpr(enum_name)
            if iscell(enum_name)
                obj.enum_name = enum_name{1};
            else
                obj.enum_name = enum_name;
            end
        end
        new_obj = deepCopy(obj)
        %% simplify expression
        new_obj = simplify(obj)
        %% nbOccurance
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
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, ~)
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(~)
            nodesCalled = {};
        end
        
        
        
        %%
        code = print(obj, backend)
        
        code = print_lustrec(obj, ~)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    
end

