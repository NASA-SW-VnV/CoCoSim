function [lines, alreadyPrinted] = printWithOrder(obj, ...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
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
