function extNode = get_interp_using_pre_node(...
    blkParams, inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    numBoundNodes = 2^blkParams.NumberOfAdjustedTableDimensions;
    
    % header for external node
    node_header.NodeName = sprintf('%s_Interp_Using_Pre_ext_node',...
        blkParams.blk_name);    
    node_header.outputs_name{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr('Interp_Using_Pre_Out');
    node_header.outputs{1} = nasa_toLustre.lustreAst.LustreVar(...
        node_header.outputs_name{1}, 'real'); 
    
    body_all = {};
    vars_all = {};    
    
    % number of inputs to this node depends on both if it is dynamic and
    % directLookup
    if LookupType.isLookupDynamic(blkParams.lookupTableType)
        if blkParams.directLookup
            node_header.inputs_name = cell(1,1+numel(inputs{3}));
            numDataBeforeTable = 1;
        else
            node_header.inputs_name = ...
                cell(1,2*numBoundNodes+numel(inputs{3}));
            numDataBeforeTable = 2*numBoundNodes;
        end
        node_header.inputs = ...
            cell(1,numel(node_header.inputs_name));
        % add in table data
        for i=1:numel(inputs{3})
            node_header.inputs_name{numDataBeforeTable+i} = ...
                nasa_toLustre.lustreAst.VarIdExpr(sprintf('ydat_%d',i));
            node_header.inputs{numDataBeforeTable+i} = ...
                nasa_toLustre.lustreAst.LustreVar(...
                node_header.inputs_name{numDataBeforeTable+i},'real');
        end
    else
        if blkParams.directLookup
            node_header.inputs_name = cell(1,1);
        else
            node_header.inputs_name = cell(1,2*numBoundNodes);
        end
        
    end

    [body, vars,table_elem] = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addTableCode(blkParams,...
        node_header, inputs);
    body_all = [body_all  body];
    vars_all = [vars_all  vars];
    
    if blkParams.directLookup    
        node_header.inputs_name{1} = ...
            nasa_toLustre.lustreAst.VarIdExpr('inline_index_solution');
        node_header.inputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            node_header.inputs_name{1},'int');
        bodyf = ...
            nasa_toLustre.blocks.Lookup_nD_To_Lustre.addInlineIndexFromArrayIndicesCode(...
            table_elem,node_header.outputs_name{1}, node_header.inputs_name{1});
        body_all = [body_all  bodyf];
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
            boundingi,table_elem,blkParams);
        body_all = [body_all  body];
        vars_all = [vars_all  vars];
        
        terms = cell(1,numBoundNodes);
        for i=1:numBoundNodes
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                N_shape_node{i},u_node{i});
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

