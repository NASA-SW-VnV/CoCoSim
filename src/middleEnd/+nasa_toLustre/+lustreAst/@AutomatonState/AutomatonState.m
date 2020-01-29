classdef AutomatonState < nasa_toLustre.lustreAst.LustreExpr
    %AutomatonState
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    properties
        name;%String
        local_vars;
        strongTrans;
        weakTrans;
        body;
    end
    
    methods
        function obj = AutomatonState(name, local_vars, strongTrans, weakTrans, body)
            obj.name = name;
            if ~iscell(local_vars)
                obj.local_vars{1} = local_vars;
            else
                obj.local_vars = local_vars;
            end
            if ~iscell(strongTrans)
                obj.strongTrans{1} = strongTrans;
            else
                obj.strongTrans = strongTrans;
            end
            if ~iscell(weakTrans)
                obj.weakTrans{1} = weakTrans;
            else
                obj.weakTrans = weakTrans;
            end
            if ~iscell(body)
                obj.body{1} = body;
            else
                obj.body = body;
            end
        end
        
        new_obj = deepCopy(obj)

        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)

        new_obj = changeArrowExp(obj, ~)
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)

        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                for i=1:numel(objects)
                    nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                end
                
            end
            addNodes(obj.strongTrans);
            addNodes(obj.weakTrans);
            addNodes(obj.body);
        end
        %% simplify expression
        new_obj = simplify(obj)

         %% nbOccuranceVar ignored in Automaton
        nb_occ = nbOccuranceVar(varargin)

        %% substituteVars ignored in Automaton
        substituteVars(obj, varargin)

        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.local_vars)
                all_obj = [all_obj; {obj.local_vars{i}}; obj.local_vars{i}.getAllLustreExpr()];
            end
            for i=1:numel(obj.strongTrans)
                all_obj = [all_obj; {obj.strongTrans{i}}; obj.strongTrans{i}.getAllLustreExpr()];
            end
            for i=1:numel(obj.weakTrans)
                all_obj = [all_obj; {obj.weakTrans{i}}; obj.weakTrans{i}.getAllLustreExpr()];
            end
            for i=1:numel(obj.body)
                all_obj = [all_obj; {obj.body{i}}; obj.body{i}.getAllLustreExpr()];
            end
        end
        %%
        code = print(obj, backend)

        code = print_lustrec(obj, backend)

        code = print_kind2(obj)

        code = print_zustre(obj)

        code = print_jkind(obj)

        code = print_prelude(obj)

    end
    
end

