classdef BooleanExpr < nasa_toLustre.lustreAst.LustreExpr
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
            if isnumeric(obj.value) || islogical(obj.value)
                v = obj.value;
            elseif ischar(obj.value)
                if strcmp(obj.value, 'true') || strcmp(obj.value, 'false')
                    v = eval(obj.value);
                else
                    if str2num(obj.value) ~= 0
                        v = true;
                    else
                        v = false;
                    end
                end
            else
                display_msg(sprintf('%s is not a lustre boolean Expression', obj.value), ...
                    MsgType.ERROR, 'BooleanExpr', '');
                v = obj.value;
            end
        end
        %%
        new_obj = deepCopy(obj)

        %% simplify expression
        new_obj = simplify(obj)

        %% nbOcc
        nb_occ = nbOccuranceVar(varargin)
        
        %% substituteVars
        new_obj = substituteVars(obj, varargin)
        
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
        code = print(obj, ~)
        
        code = print_lustrec(obj)
 
        code = print_kind2(obj)

        code = print_zustre(obj)

        code = print_jkind(obj)

        code = print_prelude(obj)

    end
    
end

