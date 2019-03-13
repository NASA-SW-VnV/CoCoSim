function node_header = getNodeCodeHeader(isLookupTableDynamic,inputs,outputs,ext_node_name)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    if ~isLookupTableDynamic
        node_inputs = cell(1, numel(inputs));
        for i=1:numel(inputs)
            node_inputs{i} = nasa_toLustre.lustreAst.LustreVar(inputs{i}{1}, 'real');
        end
    else
        node_inputs{1} = nasa_toLustre.lustreAst.LustreVar(inputs{1}{1}, 'real');
        for i=2:3
            for j=1:numel(inputs{i})
                node_inputs{end+1} = nasa_toLustre.lustreAst.LustreVar(inputs{i}{j}, 'real');
            end
        end
    end
    node_header.NodeName = ext_node_name;
    node_header.Inputs = node_inputs;
    node_header.Outputs = nasa_toLustre.lustreAst.LustreVar(outputs{1}, 'real');
end
