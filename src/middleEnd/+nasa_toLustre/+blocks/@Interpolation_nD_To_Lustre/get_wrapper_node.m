function extNode =  get_wrapper_node(...
    ~,blk,interpolationExtNode,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interpolation_using_PreLookup
   
    % node header
    wrapper_header.NodeName = ...
        sprintf('%s_Interp_with_PreLookup_wrapper_node',blkParams.blk_name);
    
    % node outputs, only y_out
    wrapper_header.output = interpolationExtNode.outputs;   
    wrapper_header.output_name{1} = nasa_toLustre.lustreAst.VarIdExpr(...
        wrapper_header.output{1}.id);

    numAdjDims = blkParams.NumberOfAdjustedTableDimensions;     
    wrapper_header.inputs = cell(1,2*numAdjDims); 
    wrapper_header.inputs_name = cell(1,2*numAdjDims); 
    for i=1:numAdjDims
        % wrapper header
        wrapper_header.inputs_name{(i-1)*2+1} = ...
            nasa_toLustre.lustreAst.VarIdExpr(sprintf('k_dim_%d',i));
        wrapper_header.inputs{(i-1)*2+1} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            wrapper_header.inputs_name{(i-1)*2+1},'int');   
        wrapper_header.inputs_name{(i-1)*2+2} = ...
            nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('fraction_dim_%d',i));
        wrapper_header.inputs{(i-1)*2+2} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            wrapper_header.inputs_name{(i-1)*2+2},'real');           
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
            wrapper_header.inputs_name{(i-1)*2+1},...
            nasa_toLustre.lustreAst.IntExpr(1));
        index_node{i,2} =  ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
            wrapper_header.inputs_name{(i-1)*2+1},...
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
            nasa_toLustre.lustreAst.LustreEq(wrapper_header.output_name{1}, ...
            nasa_toLustre.lustreAst.NodeCallExpr(...
            interpolationExtNode.name, interpolation_call_inputs_args));
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
                        wrapper_header.inputs_name{(j-1)*2+2});   % 1-fraction
                else
                    numerator_terms{j} = ...
                        wrapper_header.inputs_name{(j-1)*2+2};   % fraction
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
        bodyf{1} = nasa_toLustre.lustreAst.LustreEq(...
            wrapper_header.output_name{1}, ...
            nasa_toLustre.lustreAst.NodeCallExpr(...
            interpolationExtNode.name, ...
            interpolation_call_inputs_args));

        body_all = [body_all  bodyf];        
    end

    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(wrapper_header.NodeName)
    extNode.setInputs(wrapper_header.inputs);
    extNode.setOutputs( wrapper_header.output);
    extNode.setLocalVars(vars_all);
    extNode.setBodyEqs(body_all);
    extNode.setMetaInfo('external node code wrapper for doing Interpolation using PreLookup');

end

