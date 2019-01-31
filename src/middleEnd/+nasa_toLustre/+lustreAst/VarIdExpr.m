classdef VarIdExpr < nasa_toLustre.lustreAst.LustreExpr
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
                ME = MException('COCOSIM:LUSTREAST', ...
                    'VarIdExpr ERROR: Expected an Id of class char got a cell array of %d elements.',...
                    numel(obj.id));
                throw(ME);
            elseif isa(id, 'nasa_toLustre.lustreAst.LustreVar')
                obj.id = id.getId();
            elseif ischar(id)
                obj.id = id;
            else
                ME = MException('COCOSIM:LUSTREAST', ...
                    'VarIdExpr ERROR: Expected an Id of class char got an object of class "%s".',...
                    class(obj.id));
                throw(ME);
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
            import nasa_toLustre.lustreAst.VarIdExpr
            new_obj = VarIdExpr(obj.id);
        end
        %% simplify expression
        function new_obj = simplify(obj)
            new_obj = obj;
        end
        
        %% nbOcc
        function nb_occ = nbOccuranceVar(obj, var)
            if isequal(obj.getId(), var.getId())
                nb_occ = 1;
            else
                nb_occ = 0;
            end
        end
        %% substituteVars
        function new_obj = substituteVars(obj, var, newVar)
            if isequal(obj.getId(), var.getId())
                new_obj =  newVar;
            else
                new_obj = obj;
            end
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
            code = '';
            if ischar(obj.id)
                code = obj.id;
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
    methods(Static)
        function r = ismemberVar(v, vars)
            import nasa_toLustre.lustreAst.VarIdExpr
            import nasa_toLustre.lustreAst.LustreVar
            if iscell(v)
                r = cellfun(@(x) VarIdExpr.ismemberVar(x, vars), v);
                return;
            end
            if isa(v, 'VarIdExpr') || isa(v, 'LustreVar')
                v = v.getId();
            end
            Ids = cellfun(@(x) x.getId(), ...
                vars, 'UniformOutput', false);
            r = ismember(v, Ids);
        end
    end
end

