function extNode =  get_pre_lookup_node(lus_backend,blkParams,inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % header for external node
    NumberOfTableDimensions = ...
        blkParams.NumberOfTableDimensions;
    node_header.nodeName = sprintf('%s_PreLookup_node',...
        blkParams.blk_name);  
  
    % node_header inputs
    if nasa_toLustre.blocks.PreLookup_To_Lustre.bpIsInputPort(blkParams)
        % if breakpointsIsInputPort, inputs{1} is x, inputs{2} is xdat
        % inputs{3} is ydat and not needed     
        node_header.inputs = cell(1, 1+numel(inputs{2}));
        node_header.inputs_name = cell(1, 1+numel(inputs{2}));
        node_header.inputs_name{1} = ...
            nasa_toLustre.lustreAst.VarIdExpr('x_in');
        node_header.inputs{1} = nasa_toLustre.lustreAst.LustreVar(...
            node_header.inputs_name{1}, 'real');
        for i=1:numel(inputs{2})
            node_header.inputs_name{1+i} = ...
                nasa_toLustre.lustreAst.VarIdExpr(sprintf('xdat_%d',i));            
            node_header.inputs{1+i} = nasa_toLustre.lustreAst.LustreVar(...
                node_header.inputs_name{1+i}, 'real');
        end
    else
        % if not breakpointsIsInputPort, number of inputs equal number of
        % dimensions
        node_header.inputs = cell(1, NumberOfTableDimensions);
        node_header.inputs_name = cell(1, NumberOfTableDimensions);
        for i=1:NumberOfTableDimensions
            node_header.inputs_name{i} = nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('dim%d_coord_in',i));
            node_header.inputs{i} = ...
                nasa_toLustre.lustreAst.LustreVar(...
                node_header.inputs_name{i}, 'real');
        end
    end
    
    body_all = {};
    vars_all = {};    
    % doing subscripts to index in Lustre.  Need subscripts, and
    % dimension jump.            
    [body, vars,Ast_dimJump] = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addDimJumpCode(...
        blkParams);
    body_all = [body_all  body];
    vars_all = [vars_all  vars];   
        
    % declaring and defining break points
    % Breakpoints: breakpoint variable names
    [body, vars,Breakpoints] = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addBreakpointCode(...
        blkParams,node_header);
    body_all = [body_all  body];
    vars_all = [vars_all  vars];
    
    % get bounding nodes (corners of polygon surrounding input point)
    [body, vars,coords_node,index_node] = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addBoundNodeCode(...
        blkParams,Breakpoints,node_header.inputs_name,lus_backend);    
    body_all = [body_all  body];
    vars_all = [vars_all  vars];

    if blkParams.directLookup
        % node_header
        node_header.outputs = cell(1, 1);
        nh_out_name = cell(1, 1);
        
        nh_out_name{1} = ...
            nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('inline_index_solution'));
        node_header.outputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            nh_out_name{1}, 'int');

        % direct method  code
        [body, vars] = ...
            nasa_toLustre.blocks.Lookup_nD_To_Lustre.addDirectLookupNodeCode(...
            blkParams,index_node,coords_node, node_header.inputs_name,...
            Ast_dimJump);
        
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
            nh_out_name{1}, blkParams.direct_sol_inline_index_VarIdExpr);

    else
        % node_header      
        numBoundNodes = 2^blkParams.NumberOfTableDimensions;  
        node_header.outputs = cell(1, 2*numBoundNodes);
        nh_out_name = cell(1, 2*numBoundNodes);
        for i=1:numBoundNodes
            % node_header outputs
            nh_out_name{(i-1)*2+1} = ...
                nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('inline_index_bound_node_%d',i));
            node_header.outputs{(i-1)*2+1} = ...
                nasa_toLustre.lustreAst.LustreVar(...
                nh_out_name{(i-1)*2+1}, 'int');
            nh_out_name{(i-1)*2+2} = ...
                nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('weight_bound_node_%d',i));
            node_header.outputs{(i-1)*2+2} = ...
                nasa_toLustre.lustreAst.LustreVar(...
                nh_out_name{(i-1)*2+2}, 'real');
        end
        
        % additional solution code
        [body, vars, boundingi] = ...
            nasa_toLustre.blocks.Lookup_nD_To_Lustre.addBoundNodeInlineIndexCode(...
            index_node,Ast_dimJump,blkParams);
        
        [body_i, vars_i, N_shape_node] = ...
            nasa_toLustre.blocks.Lookup_nD_To_Lustre.addNodeWeightsCode(...
            node_header.inputs_name,coords_node,blkParams,lus_backend);
        body = [body  body_i];
        vars = [vars  vars_i];
        
        for i=1:numBoundNodes
            % define bouding inline node index
            body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
                nh_out_name{(i-1)*2+1},boundingi{i});
            % define shape function value (weight)
            body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
                nh_out_name{(i-1)*2+2},...
                N_shape_node{i});
        end        
    end

    body_all = [body_all  body];
    vars_all = [vars_all  vars];

    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(node_header.nodeName)
    extNode.setInputs(node_header.inputs);
    extNode.setOutputs(node_header.outputs);
    extNode.setLocalVars(vars_all);
    extNode.setBodyEqs(body_all);
    extNode.setMetaInfo('external node code for doing PreLookup');

end

