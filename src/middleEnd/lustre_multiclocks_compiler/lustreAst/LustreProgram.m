classdef LustreProgram < LustreAst
    %LustreProgram
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        opens;
        nodes;
        contracts;
    end
    
    methods
        function obj = LustreProgram(opens, nodes, contracts)
            if iscell(opens)
                obj.opens = opens;
            else
                obj.opens{1} = opens;
            end
            if iscell(nodes)
                obj.nodes = nodes;
            else
                obj.nodes{1} = nodes;
            end
            if iscell(contracts)
                obj.contracts = contracts;
            else
                obj.contracts{1} = contracts;
            end
        end
        
        function new_obj = deepCopy(obj)
            new_nodes = cellfun(@(x) x.deepCopy(), obj.nodes, ...
                'UniformOutput', 0);
            new_contracts = cellfun(@(x) x.deepCopy(), obj.contracts,...
                'UniformOutput', 0);
            new_obj = LustreProgram(obj.opens, new_nodes, new_contracts);
        end
        
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        function new_obj = changeArrowExp(obj, ~)
            new_obj = obj;
        end
        
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            lines = {};
            %opens
            if (BackendType.isKIND2(backend) || BackendType.isJKIND(backend))
                for i=1:numel(obj.opens)
                    lines{end+1} = sprintf('include "%s.lus"\n', ...
                        obj.opens{i});
                end
            else
                for i=1:numel(obj.opens)
                    lines{end+1} = sprintf('#open <%s>\n', ...
                        obj.opens{i});
                end
            end
            % contracts and nodes
            if BackendType.isKIND2(backend)
                nodesList = [obj.nodes, obj.contracts];
            else
                nodesList = obj.nodes;
            end
            
            if BackendType.isKIND2(backend)
                call_map = containers.Map('KeyType', 'char', ...
                    'ValueType', 'any');
                for i=1:numel(nodesList)
                    if isempty(nodesList{i})
                        continue;
                    end
                    call_map(nodesList{i}.name) = nodesList{i}.getNodesCalled();
                end
                % Print nodes in order of calling, because KIND2 Contracts
                % need all nodes used in the contract to be defined first.
                alreadyPrinted = {};
                for i=1:numel(nodesList)
                    if isempty(nodesList{i})
                        continue;
                    end
                    [lines, alreadyPrinted] = obj.printWithOrder(...
                        nodesList, nodesList{i}.name, call_map, alreadyPrinted, lines, backend);
                end
            else
                for i=1:numel(nodesList)
                    if isempty(nodesList{i})
                        continue;
                    end
                    lines{end+1} = sprintf('%s\n', ...
                        nodesList{i}.print(backend));
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
        
        function [lines, alreadyPrinted] = printWithOrder(obj, ...
                nodesList, nodeName, call_map, alreadyPrinted, lines, backend)
            if isKey(call_map, nodeName)
                subNodes = call_map(nodeName);
                for i=1:numel(subNodes)
                    [lines, alreadyPrinted] = obj.printWithOrder( ...
                        nodesList, subNodes{i}, call_map, alreadyPrinted, lines, backend);
                end
            end
            if ~ismember(nodeName, alreadyPrinted)
                Names = cellfun(@(x) x.name, ...
                    nodesList, 'UniformOutput', false);
                if ismember(nodeName, Names)
                    node = nodesList{strcmp(Names, nodeName)};
                    if ~isempty(node)
                        lines{end+1} = sprintf('%s\n', ...
                            node.print(backend));
                        alreadyPrinted{end + 1} = nodeName;
                    end
                end
            end
        end
    end
    
end

