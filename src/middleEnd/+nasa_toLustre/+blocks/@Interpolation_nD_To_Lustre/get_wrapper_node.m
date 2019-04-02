function extNode =  get_wrapper_node(...
    ~,blk,interpolation_nDExtNode,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interpolation_using_PreLookup
    
    % if outputDataType is not real, we need to cast outputs
    outputDataType = blk.CompiledPortDataTypes.Outport{1};
    lus_out_type =...
        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);

    if ~strcmp(lus_out_type,'real')
        RndMeth = blkParams.RndMeth;
        SaturateOnIntegerOverflow = blkParams.SaturateOnIntegerOverflow;
        [external_lib, output_conv_format] =...
            nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('real', ...
            lus_out_type, RndMeth, SaturateOnIntegerOverflow);
        if ~isempty(external_lib)
            obj.addExternal_libraries(external_lib);
        end
    else
        output_conv_format = {};
    end
    
    blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    numAdjDims = blkParams.NumberOfAdjustedTableDimensions;
    
    % node header
    node_header.NodeName = ...
        sprintf('%s_Interp_with_PreLookup_wrapper_node',blk_name);
    node_header.Outputs_name{1} = nasa_toLustre.lustreAst.VarIdExpr(...
        'Interp_with_PreLookup_Out');
    node_header.Outputs{1} = nasa_toLustre.lustreAst.LustreVar(...
            node_header.Outputs_name{1},'real'); 
    node_header.Inputs = cell(1,2*numAdjDims); 
    node_header.Inputs_name = cell(1,2*numAdjDims); 
    for i=1:numAdjDims
        % wrapper header
        node_header.Inputs_name{(i-1)*2+1} = ...
            nasa_toLustre.lustreAst.VarIdExpr(sprintf('k_dim_%d',i));
        node_header.Inputs{(i-1)*2+1} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            node_header.Inputs_name{(i-1)*2+1},'int');   
        node_header.Inputs_name{(i-1)*2+2} = ...
            nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('fraction_dim_%d',i));
        node_header.Inputs{(i-1)*2+2} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            node_header.Inputs_name{(i-1)*2+2},'real');           
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
    
    index_node = cell(1,2*numAdjDims); 
    for i=1:numAdjDims
        index_node{i,1} = ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
            node_header.Inputs_name{(i-1)*2+1},...
            nasa_toLustre.lustreAst.IntExpr(1));
        index_node{i,2} =  ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
            node_header.Inputs_name{(i-1)*2+1},...
            nasa_toLustre.lustreAst.IntExpr(2));
    end
    
    % calculate bounding nodes
    [body, vars, bounding_nodes] = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addBoundNodeInlineIndexCode(...
        index_node,Ast_dimJump,blkParams);
    body_all = [body_all  body];
    vars_all = [vars_all  vars];
    
    if  blkParams.directLookup
        % define args for interpolation call
        interpolation_call_inputs_args{1} = bounding_nodes{1};
        
        % call interpolation
        bodyf{1} = ...
            nasa_toLustre.lustreAst.LustreEq(node_header.Outputs_name{1}, ...
            nasa_toLustre.lustreAst.NodeCallExpr(...
            interpolation_nDExtNode.name, interpolation_call_inputs_args));
        body_all = [body_all  bodyf];
    else

        numAdjDims = blkParams.NumberOfAdjustedTableDimensions;
        numBoundNodes = 2^blkParams.NumberOfAdjustedTableDimensions;
        
        % calculating linear shape function value
        shapeNodeSign = ...
            nasa_toLustre.blocks.Lookup_nD_To_Lustre.getShapeBoundingNodeSign(...
            numAdjDims);
        N_shape_node = cell(1,numBoundNodes);
        body = cell(1,numBoundNodes);
        vars = cell(1,numBoundNodes);
        
        for i=1:numBoundNodes
            N_shape_node{i} = nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('N_shape_%d',i));
            vars{i} = nasa_toLustre.lustreAst.LustreVar(...
                N_shape_node{i},'real');
            numerator_terms = cell(1,numAdjDims);
            for j=1:numAdjDims
                if shapeNodeSign(i,j)==-1
                    numerator_terms{j} = ...
                        nasa_toLustre.lustreAst.BinaryExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
                        nasa_toLustre.lustreAst.RealExpr(1.),...
                        node_header.Inputs_name{(j-1)*2+2});   % 1-fraction
                else
                    numerator_terms{j} = ...
                        node_header.Inputs_name{(j-1)*2+2};   % fraction
                end
            end
            numerator = ...
                nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                numerator_terms);
            body{i} = nasa_toLustre.lustreAst.LustreEq(...
                N_shape_node{i},numerator);
        end
        body_all = [body_all  body];
        vars_all = [vars_all  vars];
        
        % define args for interpolation call
        interpolation_call_inputs_args = cell(1,2*numBoundNodes);
        for i=1:numBoundNodes
            interpolation_call_inputs_args{(i-1)*2+1} = bounding_nodes{i};
            interpolation_call_inputs_args{(i-1)*2+2} = N_shape_node{i};
        end
        
        % call interpolation
        bodyf{1} = ...
            nasa_toLustre.lustreAst.LustreEq(node_header.Outputs_name{1}, ...
            nasa_toLustre.lustreAst.NodeCallExpr(...
            interpolation_nDExtNode.name, interpolation_call_inputs_args));
        body_all = [body_all  bodyf];
        
    end

    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(node_header.NodeName)
    extNode.setInputs(node_header.Inputs);
    extNode.setOutputs( node_header.Outputs);
    extNode.setLocalVars(vars_all);
    extNode.setBodyEqs(body_all);
    extNode.setMetaInfo('external node code wrapper for doing Interpolation using PreLookup');

end

