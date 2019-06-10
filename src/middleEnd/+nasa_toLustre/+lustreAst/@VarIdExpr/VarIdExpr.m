classdef VarIdExpr < nasa_toLustre.lustreAst.LustreExpr
    %VarIdExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
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
        new_obj = deepCopy(obj)
        %% simplify expression
        new_obj = simplify(obj)
        
        %% nbOcc
        nb_occ = nbOccuranceVar(obj, var)
        %% substituteVars
        new_obj = substituteVars(obj, var, newVar)
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        new_obj = changeArrowExp(obj, ~)
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = {obj.id};
        end
        % this function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
        end
        
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
        end
        %%
        code = print(obj, backend)
        
        code = print_lustrec(obj, backend)
        
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
    end
    methods(Static)
        r = ismemberVar(v, vars)
    end
end

