classdef RawLustreCode < nasa_toLustre.lustreAst.LustreAst
    %RawLustreCode
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
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
        
        function new_obj = deepCopy(obj)
            new_obj = nasa_toLustre.lustreAst.RawLustreCode(obj.code, obj.name);
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
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            new_obj = obj;
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
        end
        
        
        %%
        function code = print(obj, ~)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec();
        end
        
        function code = print_lustrec(obj)
            if ischar(obj.code)
                code = obj.code;
            elseif isempty(obj.code)
                code = '';
            end
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec();
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec();
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec();
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec();
        end
    end
    
end

