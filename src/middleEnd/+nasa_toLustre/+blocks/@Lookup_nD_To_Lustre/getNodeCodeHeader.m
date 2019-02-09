
function node_header = getNodeCodeHeader(isLookupTableDynamic,inputs,outputs,ext_node_name)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if ~isLookupTableDynamic
        node_inputs = cell(1, numel(inputs));
        for i=1:numel(inputs)
            node_inputs{i} = LustreVar(inputs{i}{1}, 'real');
        end
    else
        node_inputs{1} = LustreVar(inputs{1}{1}, 'real');
        for i=2:3
            for j=1:numel(inputs{i})
                node_inputs{end+1} = LustreVar(inputs{i}{j}, 'real');
            end
        end
    end
    node_header.NodeName = ext_node_name;
    node_header.Inputs = node_inputs;
    node_header.Outputs = LustreVar(outputs{1}, 'real');
end
