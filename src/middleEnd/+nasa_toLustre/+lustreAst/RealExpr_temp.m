classdef RealExpr < nasa_toLustre.lustreAst.LustreExpr
    %RealExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        function new_obj = deepCopy(obj)
            new_obj = nasa_toLustre.lustreAst.RealExpr(obj.value);
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
        function obj = substituteVars(obj, varargin)
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
        
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(~)
            varIds = {};
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, ~)
            new_obj = obj;
        end
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(~)
            nodesCalled = {};
        end
        
        
        
        %%
        function code = print(obj, ~)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec();
        end
        
        function code = print_lustrec(obj)
            code = sprintf('%.15f', obj.getValue());
            %3.43040000 => 3.4304 code has always "." in it
            code = regexprep(code, '0+$', '0');
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

