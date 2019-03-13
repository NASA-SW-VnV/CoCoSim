function code = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    lines = {};
    %opens
    if (LusBackendType.isKIND2(backend) || LusBackendType.isJKIND(backend))
        lines = [lines; ...
            cellfun(@(x) sprintf('include "%s.lus"\n', x), obj.opens, ...
            'UniformOutput', false)];
    else
        lines = [lines; ...
            cellfun(@(x) sprintf('#open <%s>\n', x), obj.opens, ...
            'UniformOutput', false)];
    end
    
    %types
    lines = [lines; ...
        cellfun(@(x) sprintf('%s', x.print(backend)), obj.types, ...
        'UniformOutput', false)];
    
    
    % contracts and nodes
    if LusBackendType.isKIND2(backend)
        nodesList = [obj.nodes, obj.contracts];
    else
        nodesList = obj.nodes;
    end
    
    if LusBackendType.isKIND2(backend)
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
