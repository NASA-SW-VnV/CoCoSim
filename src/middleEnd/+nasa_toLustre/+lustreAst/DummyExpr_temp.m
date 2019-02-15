classdef DummyExpr < nasa_toLustre.lustreAst.LustreExpr
    %DummyExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        
    end
    
    methods
        
        function new_obj = deepCopy(obj)
            new_obj = obj;
        end
        
        %% simplify expression
        function new_obj = simplify(obj)
            new_obj = obj;
        end
        %% nbOccuranceVar
        function nb_occ = nbOccuranceVar(varargin)
            nb_occ = 0;
        end
         %% substituteVars
        function new_obj = substituteVars(obj, varargin)
            new_obj = obj;
        end
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        
        function new_obj = changeArrowExp(obj, ~)
            new_obj = obj;
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, ~)
            new_obj = obj;
        end
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(~)
            nodesCalled = {};
        end
        
        
        
        %%
        function code = print(varargin)
            code = '';
        end
        function code = print_lustrec(varargin)
            code = '';
        end
        function code = print_kind2(varargin)
            code = '';
        end
        function code = print_zustre(varargin)
            code = '';
        end
        function code = print_jkind(varargin)
            code = '';
        end
        function code = print_prelude(varargin)
            code = '';
        end
        
    end
    
end

