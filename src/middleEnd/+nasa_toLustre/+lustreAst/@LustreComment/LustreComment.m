classdef LustreComment < nasa_toLustre.lustreAst.LustreExpr
    %LustreComment
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        text;
        isMultiLine;
    end
    
    methods
        function obj = LustreComment(text, isMultiLine)
            obj.text = text;
            if nargin < 2
                obj.isMultiLine = false;
            else
                obj.isMultiLine = isMultiLine;
            end
        end
        
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
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, varargin)
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(varargin)
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

