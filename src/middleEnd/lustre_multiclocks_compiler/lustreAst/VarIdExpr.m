classdef VarIdExpr < LustreExpr
    %VarIdExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        id;%String
    end
    
    methods
        function obj = VarIdExpr(id)
            if iscell(id) && numel(id) == 1
                obj.id = id{1};
            elseif iscell(id)
                obj.id = TupleExpr(id);
            else
                obj.id = id;
            end
        end
        function id = getId(obj)
            id = obj.id;
        end
        function setId(obj, name)
            obj.id = name;
        end
        
        %% deep copy
        function new_obj = deepCopy(obj)
            new_obj = VarIdExpr(obj.id);
        end
        %% simplify expression
        function new_obj = simplify(obj)
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
        function varIds = GetVarIds(obj)
            varIds = {obj.id};
        end
        % this function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            new_obj = obj.deepCopy();
            if ~isempty(outputs_map) && isKey(outputs_map, obj.getId())
                occ = outputs_map(obj.getId());
                if isLeft
                    %increase number of occurance
                    occ = occ + 1;
                end
                if occ > 0
                    new_obj.setId(strcat(obj.getId(), '__', num2str(occ)));
                    outputs_map(obj.getId()) = occ;
                end
            end
        end
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
        end
        
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            if ischar(obj.id)
                code = obj.id;
            elseif isa(obj.id, 'LustreExpr')
                %Should not happen.
                code = obj.id.print(backend);
            end
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(BackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(BackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(BackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(BackendType.PRELUDE);
        end
    end
    methods(Static)
        function r = ismemberVar(v, vars)
            Ids = cellfun(@(x) x.getId(), ...
                vars, 'UniformOutput', false);
            r = ismember(v, Ids);
        end
    end
end

