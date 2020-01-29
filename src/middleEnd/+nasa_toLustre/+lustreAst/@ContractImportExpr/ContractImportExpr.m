classdef ContractImportExpr < nasa_toLustre.lustreAst.LustreExpr
    %ContractImportExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    properties
        name; %String
        inputs;
        outputs;
    end
    
    methods
        function obj = ContractImportExpr(name, inputs, outputs)
            obj.name = name;
            if ~iscell(inputs)
                obj.inputs{1} = inputs;
            else
                obj.inputs = inputs;
            end
            if ~iscell(outputs)
                obj.outputs{1} = outputs;
            else
                obj.outputs = outputs;
            end
        end
        
        new_obj = deepCopy(obj)

        %% simplify expression
        new_obj = simplify(obj)

        %% nbOccurance
        nb_occ = nbOccuranceVar(obj, var)

        %% substituteVars 
        new_obj = substituteVars(obj, oldVar, newVar)

        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.inputs)
                all_obj = [all_obj; {obj.inputs{i}}; obj.inputs{i}.getAllLustreExpr()];
            end
            for i=1:numel(obj.outputs)
                all_obj = [all_obj; {obj.outputs{i}}; obj.outputs{i}.getAllLustreExpr()];
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
            addNodes(obj.inputs);
            addNodes(obj.outputs);
            nodesCalled{end+1} = obj.name;
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)

        %%
        code = print(obj, backend)

        code = print_lustrec(obj)

        code = print_kind2(obj, backend)

        code = print_zustre(obj)

        code = print_jkind(obj)

        code = print_prelude(obj)

    end
    
end

