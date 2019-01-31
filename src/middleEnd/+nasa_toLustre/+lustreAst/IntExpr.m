classdef IntExpr < nasa_toLustre.lustreAst.LustreExpr
    %IntExpr
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
        function obj = IntExpr(v)
            obj.value = v;
        end
        %%
        function v = getValue(obj)
            if isnumeric(obj.value) || islogical(obj.value)
                v =  obj.value;
            elseif ischar(obj.value)
                v = int32(str2num(obj.value));
            else
                display_msg(sprintf('%s is not a lustre Int Expression', obj.value), ...
                    MsgType.ERROR, 'IntExpr', '');
                v = obj.value;
            end
        end
        %%
        function new_obj = deepCopy(obj)
            new_obj = nasa_toLustre.lustreAst.IntExpr(obj.value);
        end
        %% simplify expression
        function new_obj = simplify(obj)
            if isnumeric(obj.value) && obj.value < 0
                % -1 => -(1)
                new_obj = nasa_toLustre.lustreAst.UnaryExpr(UnaryExpr.NEG, IntExpr(-obj.value));
            else
                new_obj = obj;
            end
        end
        %% nbOccurance
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
            code = sprintf('%.0f', obj.getValue());
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

