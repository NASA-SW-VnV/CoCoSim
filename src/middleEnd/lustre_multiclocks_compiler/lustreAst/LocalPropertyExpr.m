classdef LocalPropertyExpr < LustreExpr
    %LocalPropertyExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        id; %String
        exp; %LustreExp
    end
    
    methods
        function obj = LocalPropertyExpr(id, exp)
            obj.id = id;
            if iscell(exp)
                obj.exp = exp{1};
            else
                obj.exp = exp;
            end
        end
        function new_obj = deepCopy(obj)
            new_obj = LocalPropertyExpr(obj.id, ...
                obj.exp.deepCopy());
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
            varIds = obj.exp.GetVarIds;
        end
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.exp);
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            [new_exp, outputs_map] = obj.exp.pseudoCode2Lustre(outputs_map, isLeft);
            new_obj = LocalPropertyExpr(obj.id, new_exp);
        end
        %%
        function code = print(obj, backend)
            if BackendType.isPRELUDE(backend)
                code = obj.print_prelude();
            else
                %TODO: check if KIND2 syntax is OK for the other backends.
                code = obj.print_kind2(backend);
            end
        end
        
        
        function code = print_lustrec(obj, backend)
            code = obj.print_kind2(backend);
        end
        function code = print_kind2(obj, backend)
            if isempty(obj.id)
                code = sprintf('--%%PROPERTY %s;', ...
                    obj.exp.print(backend));
            else
                code = sprintf('--%%PROPERTY "%s" %s;', ...
                    obj.id, ...
                    obj.exp.print(backend));
            end
        end
        function code = print_zustre(obj, backend)
            code = obj.print_kind2(backend);
        end
        function code = print_jkind(obj, backend)
            code = obj.print_kind2(backend);
        end
        function code = print_prelude(obj)
            code = '';
        end
    end
    
end

