classdef LustreVar < LustreAst
    %LustreVar
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name;%String
        type;%String
    end
    
    methods
        function obj = LustreVar(name, type)
            if isa(name, 'VarIdExpr')
                obj.name = name.getId();
            elseif iscell(name) && numel(name) == 1
                obj.name = name{1};
            else
                obj.name = name;
            end
            if iscell(type) && numel(type) == 1
                obj.type = type{1};
            else
                obj.type = type;
            end
        end
        
        function new_obj = deepCopy(obj)
            new_obj = LustreVar(obj.name, obj.type);
        end
        
        %% simplify expression
        function new_obj = simplify(obj)
            new_obj = obj;
        end
        
        %% nbOccuranceVar
        function nb_occ = nbOccuranceVar(~, ~)
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
        function varIds = GetVarIds(obj)
            varIds = {obj.name};
        end
        % this function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            vId = VarIdExpr(obj.name);
            [new_vId, outputs_map] = vId.pseudoCode2Lustre(outputs_map, isLeft);
            new_obj = LustreVar(new_vId, obj.type);
        end
        %%
        function id = getId(obj)
            id = obj.name;
        end
        function dt = getDT(obj)
            dt = obj.type;
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
            if BackendType.isKIND2(backend) ...
                    && isequal(obj.type, 'bool clock')
                dt = 'bool';
            else
                dt = obj.type;
            end
            
            code = sprintf('%s : %s;', obj.name, dt);
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
        function U = uniqueVars(vars)
            Ids = cellfun(@(x) x.getId(), ...
                vars, 'UniformOutput', false);
            [~, I] = unique(Ids);
            U = vars(I);
        end
        function U = removeVar(vars, v)
            if isa(v, 'VarIdExpr') || isa(v, 'LustreVar')
                v = v.getId();
            end
            Ids = cellfun(@(x) x.getId(), ...
                vars, 'UniformOutput', false);
            U = vars(~strcmp(Ids, v));
        end
    end
end

