classdef EnumTypeExpr < nasa_toLustre.lustreAst.LustreExpr
    %EnumTypeExpr: e.g. type Direction = enum {North, South, East, West};
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        enum_name;
        enum_args;
    end
    
    methods
        function obj = EnumTypeExpr(enum_name, enum_args)
            if iscell(enum_name)
                obj.enum_name = enum_name{1};
            else
                obj.enum_name = enum_name;
            end
            if ~iscell(enum_args)
                obj.enum_args{1} = enum_args;
            else
                obj.enum_args = enum_args;
            end
            % transform args from String to EnumValueExpr
            for i=1:numel(obj.enum_args)
                if ischar(obj.enum_args{i})
                    obj.enum_args{i} = nasa_toLustre.lustreAst.EnumValueExpr(obj.enum_args{i});
                end
            end
        end
        
        function enum_args = getEnumArgs(obj)
            enum_args = obj.enum_args;
        end
        function  setEnumArgs(obj, enum_args)
            if ~iscell(enum_args)
                obj.enum_args{1} = enum_args;
            else
                obj.enum_args = enum_args;
            end
        end
        
        new_obj = deepCopy(obj)
        %% simplify expression
        new_obj = simplify(obj)
        %% nbOccurance
        nb_occ = nbOccuranceVar(obj, var)
        %% substituteVars 
        new_obj = substituteVars(obj, varargin)
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.enum_args)
                all_obj = [all_obj; {obj.enum_args{i}}; obj.enum_args{i}.getAllLustreExpr()];
            end
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
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    
end

