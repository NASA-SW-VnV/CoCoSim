classdef LustreComment < nasa_toLustre.lustreAst.LustreExpr
    %LustreComment
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
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
        
        function new_obj = deepCopy(obj)
            new_obj = LustreComment(obj.text,...
                obj.isMultiLine);
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
        function nodesCalled = getNodesCalled(varargin)
            nodesCalled = {};
        end
        
        
        
        %%
        function code = print(obj, backend)
            code = obj.print_lustrec(backend);
        end
        function code = print_lustrec(obj, ~)
            if isempty(obj.text)
                return;
            end
            if obj.isMultiLine
                code = sprintf('(*\n%s\n*)\n', ...
                    obj.text);
            else
                code = sprintf('--%s', ...
                    obj.text);
            end
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

