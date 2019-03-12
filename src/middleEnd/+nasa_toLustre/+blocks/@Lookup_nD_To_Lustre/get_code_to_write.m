function [ mainCode, main_vars, extNode, external_lib] =  ...
        get_code_to_write(parent, blk, xml_trace,isLookupTableDynamic,lus_backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    % initialize
    indexDataType = 'int';
    blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    ext_node_name = sprintf('%s_ext_node',blk_name);   
    external_lib = {'LustMathLib_abs_real'};

    % get block outputs
    [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);

    % get block inputs
    [inputs,lusInport_dt,~,~,  external_lib_i] = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.getBlockInputsNames_convInType2AccType(parent, blk,isLookupTableDynamic);
    if ~isempty(external_lib_i)
        external_lib{end+1} = external_lib_i;
    end

    % read block parameters
    blkParams = nasa_toLustre.blocks.Lookup_nD_To_Lustre.readBlkParams(parent,blk,isLookupTableDynamic,inputs);

    % For n-D Lookup Table, if UseOneInputPortForAllInputData is
    % selected, Combine all input data to one input port
    inputs = nasa_toLustre.blocks.Lookup_nD_To_Lustre.useOneInputPortForAllInputData(blk,isLookupTableDynamic,inputs,blkParams.NumberOfTableDimensions);

    % writing external node code
    %node header
    node_header = nasa_toLustre.blocks.Lookup_nD_To_Lustre.getNodeCodeHeader(isLookupTableDynamic,...
        inputs,outputs,ext_node_name);

    % declaring and defining table values
    [body, vars,table_elem] = nasa_toLustre.blocks.Lookup_nD_To_Lustre.addTableCode(blkParams.Table,blk_name,...
        lusInport_dt,isLookupTableDynamic,inputs);
    body_all = body;
    vars_all = vars;

    % declaring and defining break points
    [body, vars,Breakpoints] = nasa_toLustre.blocks.Lookup_nD_To_Lustre.addBreakpointCode(...
        blkParams.BreakpointsForDimension,blk_name,lusInport_dt,isLookupTableDynamic,...
        inputs,blkParams.NumberOfTableDimensions);
    body_all = [body_all  body];
    vars_all = [vars_all  vars];

    % defining u
    % doing subscripts to index in Lustre.  Need subscripts, and
    % dimension jump.            
    [body, vars,Ast_dimJump] = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addDimJumpCode(blkParams.NumberOfTableDimensions,...
        blk_name,indexDataType,blkParams.BreakpointsForDimension);
    body_all = [body_all  body];
    vars_all = [vars_all  vars];

    % get bounding nodes (corners of polygon surrounding input point)
    [body, vars,numBoundNodes,u_node,N_shape_node,coords_node,index_node] = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addBoundNodeCode(blkParams,...
        blk_name,...
        Breakpoints,...
        lusInport_dt,...
        indexDataType,...
        inputs,...
        lus_backend);
    body_all = [body_all  body];
    vars_all = [vars_all  vars];

    % Need shape functions if interpolation
    if ~blkParams.skipInterpolation
        shapeNodeSign = nasa_toLustre.blocks.Lookup_nD_To_Lustre.getShapeBoundingNodeSign(blkParams.NumberOfTableDimensions);
        [body, vars] = nasa_toLustre.blocks.Lookup_nD_To_Lustre.addShapeFunctionCode(...
            numBoundNodes,shapeNodeSign,blk_name,indexDataType,table_elem,...
            blkParams.NumberOfTableDimensions,index_node,Ast_dimJump,blkParams.skipInterpolation,u_node);
        body_all = [body_all  body];
        vars_all = [vars_all  vars];
        [bodyf, varsf] = nasa_toLustre.blocks.Lookup_nD_To_Lustre.addFinalCode_with_interpolation( ...
            outputs,inputs,blk_name,...
            blkParams,blk,...
            N_shape_node,coords_node,lusInport_dt,...
            shapeNodeSign,u_node, lus_backend);
        body_all = [body_all  bodyf];
        vars_all = [vars_all  varsf];
    else                
        [bodyf, varsf] = nasa_toLustre.blocks.Lookup_nD_To_Lustre.addFinalCode_without_interpolation( ...
            outputs,inputs,indexDataType,blk_name,...
            blkParams,...
            coords_node,lusInport_dt,...
            index_node,Ast_dimJump,table_elem, lus_backend);
        body_all = [body_all  bodyf];
        vars_all = [vars_all  varsf];                
    end

    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(node_header.NodeName)
    extNode.setInputs(node_header.Inputs);
    extNode.setOutputs( node_header.Outputs);
    extNode.setLocalVars(vars_all);
    extNode.setBodyEqs(body_all);
    extNode.setMetaInfo('external node code for doing Lookup_nD');

    if LusBackendType.isKIND2(lus_backend) ...
            && ~isLookupTableDynamic ...
            && blkParams.NumberOfTableDimensions <= 3
        contractBody = nasa_toLustre.blocks.Lookup_nD_To_Lustre.getContractBody(blkParams,inputs,outputs);
        contract = nasa_toLustre.lustreAst.LustreContract();
        contract.setBodyEqs(contractBody);
        extNode.setLocalContract(contract);
        if blkParams.NumberOfTableDimensions == 3
            %complicated to prove
            extNode.setIsImported(true);
        end
    end
    main_vars = outputs_dt;
    % if outputDataType is not real, we need to cast outputs
    outputDataType = blk.CompiledPortDataTypes.Outport{1};
    lus_out_type =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
    if ~strcmp(lus_out_type,'real')
        RndMeth = blk.RndMeth;
        SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
        [external_lib_i, output_conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('real', ...
            lus_out_type, RndMeth, SaturateOnIntegerOverflow);
        if ~isempty(external_lib_i)
            external_lib(end+1) = external_lib_i;
        end
    else
        output_conv_format = {};
    end            
    mainCode = nasa_toLustre.blocks.Lookup_nD_To_Lustre.getMainCode(outputs,inputs,...
        ext_node_name,isLookupTableDynamic,output_conv_format);

end

