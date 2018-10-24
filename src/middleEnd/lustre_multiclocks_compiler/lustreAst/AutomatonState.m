classdef AutomatonState < LustreExpr
    %AutomatonState
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name;%String
        local_vars;
        strongTrans;
        weakTrans;
        body;
    end
    
    methods 
        function obj = AutomatonState(name, local_vars, strongTrans, weakTrans, body)
            obj.name = name;
            obj.local_vars = local_vars;
            obj.strongTrans = strongTrans;
            obj.weakTrans = weakTrans;
            obj.body = body;
        end
        
        function new_obj = deepCopy(obj)
            if iscell(obj.local_vars)
                new_local_vars = cellfun(@(x) x.deepCopy(), obj.local_vars, 'UniformOutput', 0);
            else
                new_local_vars = obj.local_vars.deepCopy();
            end
            if iscell(obj.strongTrans)
                new_strongTrans = cellfun(@(x) x.deepCopy(), obj.strongTrans, 'UniformOutput', 0);
            else
                new_strongTrans = obj.strongTrans.deepCopy();
            end
            if iscell(obj.weakTrans)
                new_weakTrans = cellfun(@(x) x.deepCopy(), obj.weakTrans, 'UniformOutput', 0);
            else
                new_weakTrans = obj.weakTrans.deepCopy();
            end
            if iscell(obj.body)
                new_body = cellfun(@(x) x.deepCopy(), obj.body, 'UniformOutput', 0);
            else
                new_body = obj.body.deepCopy();
            end
            new_obj = AutomatonState(obj.name, new_local_vars, ...
                new_strongTrans, new_weakTrans, new_body);
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        function new_obj = changeArrowExp(obj, ~)
            new_obj = obj;
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                if iscell(objects)
                    for i=1:numel(objects)
                        nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                    end
                else
                    nodesCalled = [nodesCalled, objects.getNodesCalled()];
                end
            end
            addNodes(obj.strongTrans);
            addNodes(obj.weakTrans);
            addNodes(obj.body);
        end
        %%
        function code = print(obj, backend)
            %TODO: check if lustrec syntax is OK for jkind and prelude.
            code = obj.print_lustrec(backend);
        end
        function code = print_lustrec(obj, backend)
            lines = {};
            lines{1} = sprintf('\tstate %s:\n', obj.name);
            % Strong transition
            if iscell(obj.strongTrans)
                for i=1:numel(obj.strongTrans)
                    lines{end+1} = sprintf('\tunless %s', ...
                        obj.strongTrans{i}.print(backend));
                end
            else
                for i=1:numel(obj.strongTrans)
                    lines{end+1} = sprintf('\tunless %s', ...
                        obj.strongTrans(i).print(backend));
                end
            end
            %local variables
            if ~isempty(obj.local_vars)
                lines{end + 1} = sprintf('var %s\n', ...
                    LustreAst.listVarsWithDT(obj.local_vars, backend));
            end
            % body
            lines{end+1} = sprintf('\tlet\n');
            for i=1:numel(obj.body)
                lines{end+1} = sprintf('\t\t%s\n', ...
                        obj.body{i}.print(backend));
            end
            lines{end+1} = sprintf('\ttel\n');
            % weak transition
            if iscell(obj.weakTrans)
                for i=1:numel(obj.weakTrans)
                    lines{end+1} = sprintf('\tuntil %s\n', ...
                        obj.weakTrans{i}.print(backend));
                end
            else
                for i=1:numel(obj.weakTrans)
                    lines{end+1} = sprintf('\tuntil %s\n', ...
                        obj.weakTrans(i).print(backend));
                end
            end
            code = MatlabUtils.strjoin(lines, '');
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

end

