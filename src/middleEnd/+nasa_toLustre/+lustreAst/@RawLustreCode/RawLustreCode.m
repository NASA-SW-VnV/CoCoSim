classdef RawLustreCode < nasa_toLustre.lustreAst.LustreAst
    %RawLustreCode
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        code
        name
    end
    
    methods
        function obj = RawLustreCode(code, name)
            obj.code = code;
            if nargin == 2
                %for Raw Lustre Node
                obj.name = name;
            else
                obj.name = '';
            end
        end
        
        new_obj = deepCopy(obj)
        
        %% simplify expression
        new_obj = simplify(obj)
        %% nbOccuranceVar
        nb_occ = nbOccuranceVar(varargin)
        %% substituteVars
        substituteVars(obj, varargin)
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        new_obj = changeArrowExp(obj, ~)
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
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

