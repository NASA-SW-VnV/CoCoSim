classdef BooleanExpr < LustreExpr
    %BooleanExpr
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
        function obj = BooleanExpr(v)
            obj.value = v;
        end
        %%
        function v = getValue(obj)
            v = obj.value;
        end
        %%
        function new_obj = deepCopy(obj)
            new_obj = BooleanExpr(obj.value);
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
        function varIds = GetVarIds(obj)
            varIds = {};
        end
        %%
        function code = print(obj, ~)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec();
        end
        
        function code = print_lustrec(obj)
            if isnumeric(obj.value) || islogical(obj.value)
                if obj.value
                    code = 'true';
                else
                    code = 'false';
                end
            elseif ischar(obj.value)
                if isequal(obj.value, 'true') || isequal(obj.value, 'false')
                    code = obj.value;
                else
                    if str2num(obj.value) ~= 0
                        code = 'true';
                    else
                        code = 'false';
                    end
                end
            else
                display_msg(sprintf('%s is not a lustre boolean Expression', obj.value), ...
                    MsgType.ERROR, 'BooleanExpr', '');
                code = obj.value;
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

