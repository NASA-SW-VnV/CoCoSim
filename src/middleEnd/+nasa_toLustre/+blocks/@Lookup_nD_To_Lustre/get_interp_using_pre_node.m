function extNode = get_interp_using_pre_node(obj, ...
    blkParams, inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This function generate Lustre external node that will return y value
    % (solution).  
    % There are 2 very different solution methods: 
    % 1.  the direct lookup method in which the
    % y value at a breakpoint is the solution.  This is just an element of
    % the table defined by the user.  For this method, the input is the
    % inline index of the solution. This function then just return the
    % corresponding table element.
    % 2.  the interpolation method in which the solution is interpolated
    % from the polytop that surround the input point.
    % The inputs to this function are the inline indices and the weights of
    % the polytop (nodes surrounding the input point).  4 inputs are
    % required for each dimention.  Inline index of the lower bounding
    % node, weight of the lower bounding node, inline index of the
    % upper bounding node, and weight of the upper bounding node.  The y
    % solution is then just sumation of y(node i)*weight(node i) where i
    % is all nodes in the polytop.  The number of nodes in the polytop is
    % numBoundNodes.  
    % For Dynamic lookup the table values are also input
    % after the solution index for direct lookup or node indices and 
    % weights for interpolated method.

    % create read table node
    readTableNode = nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_read_table_node(blkParams, inputs);
    obj.addExtenal_node(readTableNode);
    readTableNodeName = readTableNode.getName();
   
    numBoundNodes = 2^blkParams.NumberOfTableDimensions;
    
    % header for external node
    node_header.NodeName = sprintf('%s_Interp_Using_Pre_ext_node',...
        blkParams.blk_name);    
    node_header.outputs_name{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr('Interp_Using_Pre_Out');
    node_header.outputs{1} = nasa_toLustre.lustreAst.LustreVar(...
        node_header.outputs_name{1}, 'real'); 
    
    body_all = {};
    vars_all = {};    
    
    % number of inputs to this node depends on both if the table is input port
    if blkParams.tableIsInputPort
        if blkParams.directLookup
            node_header.inputs_name = cell(1,1+numel(inputs{end}));
            numDataBeforeTable = 1;
        else
            node_header.inputs_name = ...
                cell(1,2*numBoundNodes+numel(inputs{end}));
            numDataBeforeTable = 2*numBoundNodes;
        end
        node_header.inputs = ...
            cell(1,numel(node_header.inputs_name));
        % add in table data
        readTableInputs = cell(1, 1+numel(inputs{end}));
        for i=1:numel(inputs{end})
            ydatName = sprintf('ydat_%d',i);
            readTableInputs{i+1} = nasa_toLustre.lustreAst.VarIdExpr(ydatName);
            node_header.inputs_name{numDataBeforeTable+i} = ...
                nasa_toLustre.lustreAst.VarIdExpr(ydatName);
            node_header.inputs{numDataBeforeTable+i} = ...
                nasa_toLustre.lustreAst.LustreVar(ydatName, 'real');
        end

    else
        readTableInputs = {};
        if blkParams.directLookup
            node_header.inputs_name = cell(1,1);
        else
            node_header.inputs_name = cell(1,2*numBoundNodes);
        end
    end
    
    if blkParams.directLookup    
        node_header.inputs_name{1} = ...
            nasa_toLustre.lustreAst.VarIdExpr('inline_index_solution');
        node_header.inputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            node_header.inputs_name{1},'int');
        readTableInputs{1} = node_header.inputs_name{1};
        body_all{end+1} = nasa_toLustre.lustreAst.LustreEq(...
            node_header.outputs_name{1}, ...
            nasa_toLustre.lustreAst.NodeCallExpr(readTableNodeName, readTableInputs));
        
    else
        % node header inputs
        boundingi = cell(1, numBoundNodes);
        N_shape_node = cell(1, numBoundNodes);        
        for i=1:numBoundNodes
            indexName = sprintf('inline_index_bound_node_%d',i);
            boundingi{i} = nasa_toLustre.lustreAst.VarIdExpr(indexName);
            node_header.inputs{(i-1)*2+1} = ...
                nasa_toLustre.lustreAst.LustreVar(indexName, 'int');            
            shapeName = sprintf('weight_bound_node_%d',i);
            N_shape_node{i} = nasa_toLustre.lustreAst.VarIdExpr(shapeName);
            node_header.inputs{(i-1)*2+2} = ...
                nasa_toLustre.lustreAst.LustreVar(shapeName, 'real');
            node_header.inputs_name{(i-1)*2+1} = boundingi{i};
            node_header.inputs_name{(i-1)*2+2} = N_shape_node{i};            
        end
        
        [body, vars,u_node] = ...
            nasa_toLustre.blocks.Lookup_nD_To_Lustre.addUnodeCode(...
            boundingi,blkParams, readTableNodeName, readTableInputs);
        body_all = [body_all  body];
        vars_all = [vars_all  vars];
        
        terms = cell(1,numBoundNodes);
        for i=1:numBoundNodes
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                N_shape_node{i},u_node{i});
            terms{i}.setOperandsDT('real');
        end
        
        rhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS,terms);
        body_all{end+1} = nasa_toLustre.lustreAst.LustreEq(...
            node_header.outputs_name{1},rhs);
    end

    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(node_header.NodeName)
    extNode.setInputs(node_header.inputs);
    extNode.setOutputs(node_header.outputs);
    extNode.setLocalVars(vars_all);
    extNode.setBodyEqs(body_all);
    extNode.setMetaInfo('external node code for doing Interpolation Using PreLookup');

end

