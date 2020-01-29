function extNode = get_read_table_node(...
        blkParams, inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % This function generate Lustre external node that will return y value
    % from a table
    
    
    % header for external node
    node_header.NodeName = sprintf('%s_getTableElement',...
        blkParams.blk_name);
    node_header.outputs_name{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr('y');
    node_header.outputs{1} = nasa_toLustre.lustreAst.LustreVar(...
        node_header.outputs_name{1}, 'real');
    
    body_all = {};
    vars_all = {};
    
    % number of inputs to this node depends on both if the table is input port
    node_header.inputs_name{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr('x');
    node_header.inputs{1} = ...
        nasa_toLustre.lustreAst.LustreVar(...
        node_header.inputs_name{1},'int');
    if blkParams.tableIsInputPort
        table_elem = cell(1, numel(inputs{end}));
        for i=1:numel(inputs{end})
            ydatName = sprintf('ydat_%d',i);
            table_elem{i} = nasa_toLustre.lustreAst.VarIdExpr(ydatName);
            node_header.inputs_name{end+1} = ...
                nasa_toLustre.lustreAst.VarIdExpr(ydatName);
            node_header.inputs{end+1} = ...
                nasa_toLustre.lustreAst.LustreVar(ydatName, 'real');
        end
    else
        [body_all, vars_all, table_elem] = ...
            nasa_toLustre.blocks.Lookup_nD_To_Lustre.addTableCode(blkParams,...
            node_header);
    end
    
    [bodyf, vars] = nasa_toLustre.blocks.Lookup_nD_To_Lustre.addInlineIndexFromArrayIndicesCode(...
        table_elem, node_header.outputs_name{1},  node_header.inputs_name{1}, 'real');
    vars = nasa_toLustre.lustreAst.LustreVar.removeVar(vars, node_header.outputs_name{1});
    
    body_all = [body_all  bodyf];
    vars_all = [vars_all, vars];
    
    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(node_header.NodeName)
    extNode.setInputs(node_header.inputs);
    extNode.setOutputs(node_header.outputs);
    extNode.setLocalVars(vars_all);
    extNode.setBodyEqs(body_all);
    extNode.setMetaInfo('get a table element');
    
end

