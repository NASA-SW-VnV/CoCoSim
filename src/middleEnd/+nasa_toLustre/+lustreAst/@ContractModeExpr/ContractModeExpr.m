classdef ContractModeExpr < nasa_toLustre.lustreAst.LustreExpr
    %ContractModeExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name; %String
        requires; %LustreExp[]
        ensures; %LustreExp[]
    end
    
    methods
        function obj = ContractModeExpr(name, requires, ensures)
            obj.name = name;
            if ~iscell(requires)
                obj.requires{1} = requires;
            else
                obj.requires = requires;
            end
            if ~iscell(ensures)
                obj.ensures{1} = ensures;
            else
                obj.ensures = ensures;
            end
            require_class = unique( cellfun(@(x) class(x), obj.requires, 'UniformOutput', 0));
            ensures_class = unique( cellfun(@(x) class(x), obj.ensures, 'UniformOutput', 0));
            % check the object is a valid Lustre AST.
            if ~( length(require_class) == 1 ...
                    && strcmp(require_class{1}, 'nasa_toLustre.lustreAst.ContractRequireExpr'))
                ME = MException('COCOSIM:LUSTREAST', ...
                    'ContractModeExpr ERROR: Expected second parameter of type "ContractRequireExpr" Got type "%s".',...
                    MatlabUtils.strjoin(require_class, ', '));
                throw(ME);
            end
            if ~( length(ensures_class) == 1 ...
                    && strcmp(ensures_class{1}, 'nasa_toLustre.lustreAst.ContractEnsureExpr'))
                ME = MException('COCOSIM:LUSTREAST', ...
                    'ContractModeExpr ERROR: Expected third parameter of type "ContractEnsureExpr" Got type "%s".',...
                    MatlabUtils.strjoin(ensures_class, ', '));
                throw(ME);
            end
        end
        
        new_obj = deepCopy(obj)

        %% simplify expression
        new_obj = simplify(obj)
        
        %% nbOccurance
        nb_occ = nbOccuranceVar(obj, var)

        %% substituteVars 
        new_obj = substituteVars(obj, oldVar, newVar)

        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.requires)
                all_obj = [all_obj; {obj.requires{i}}; obj.requires{i}.getAllLustreExpr()];
            end
            for i=1:numel(obj.ensures)
                all_obj = [all_obj; {obj.ensures{i}}; obj.ensures{i}.getAllLustreExpr()];
            end
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)

        new_obj = changeArrowExp(obj, ~)
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                for i=1:numel(objects)
                    nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                end
            end
            addNodes(obj.requires);
            addNodes(obj.ensures);
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)        
        
        %%
        code = print(obj, backend)

        code = print_lustrec(obj)

        code = print_kind2(obj, backend)

        code = print_zustre(obj)

        code = print_jkind(obj)

        code = print_prelude(obj)

    end
    
end

