function extNode =  get_wrapper_node(obj,blk,...
    blkParams,inputs,outputs,preLookUpExtNode,interpolationExtNode)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LookupTableDynamic
    
    % if outputDataType is not real, we need to cast outputs
    outputDataType = blk.CompiledPortDataTypes.Outport{1};
    lus_out_type =...
        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
    blk_name = blkParams.blk_name;
    
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
    
    % node header
    node_header.NodeName =  sprintf('%s_Lookup_wrapper_retrieval_node',blk_name);
    % node header inputs
    node_inputs = cell(1, numel(inputs));
    for i=1:numel(inputs)
        node_inputs{i} = ...
            nasa_toLustre.lustreAst.LustreVar(inputs{i}{1}, 'real');
    end
    node_header.Inputs = node_inputs;
    % node outputs
    node_outputs = cell(1,numel(outputs));
    for i=1:numel(outputs)
        node_outputs{i} = ...
            nasa_toLustre.lustreAst.LustreVar(outputs{i}, lus_out_type);
    end
    node_header.Outputs = node_outputs;
    
    % Pre look up out
    if blkParams.directLookup
        solution_name{1} = nasa_toLustre.lustreAst.VarIdExpr(...
            preLookUpExtNode.outputs{1}.name);
        vars{1} = nasa_toLustre.lustreAst.LustreVar(solution_name{1}, 'real');
    else
        numBoundNodes = 2^blkParams.NumberOfAdjustedTableDimensions;
        vars = cell(1,2*numBoundNodes);
        prelookup_out = cell(1,numel(vars));
        for i=1:numBoundNodes
            % node_header outputs
            prelookup_out{(i-1)*2+1} = ...
                nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('inline_index_bound_node_%d',i));
            prelookup_out{(i-1)*2+2} = ...
                nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('weight_bound_node_%d',i));
            vars{(i-1)*2+1} = ...
                nasa_toLustre.lustreAst.LustreVar(...
                prelookup_out{(i-1)*2+1},'int');
            vars{(i-1)*2+2} = ...
                nasa_toLustre.lustreAst.LustreVar(...
                prelookup_out{(i-1)*2+2},'real');
        end
    end
    
    
    % body, for each interpolation, make a call to prelookup and a call to
    % interpolation_using_prelookup
    body = cell(1, 2*numel(outputs));
    for outIdx=1:numel(outputs)
        nodeCall_inputs = {};
        if LookupType.isLookupDynamic(blkParams.lookupTableType)
            nodeCall_inputs{end+1} = inputs{1}{outIdx};
            for i=2:numel(inputs)
                nodeCall_inputs = [nodeCall_inputs, inputs{i}];
            end
        else
            nodeCall_inputs = cell(1, numel(inputs));
            for i=1:numel(inputs)
                nodeCall_inputs{i} = inputs{i}{outIdx};
            end
        end
        if blkParams.directLookup
            % call prelookup
            body{(outIdx-1)*2+outIdx} = nasa_toLustre.lustreAst.LustreEq(solution_name{1}, ...
                nasa_toLustre.lustreAst.NodeCallExpr(preLookUpExtNode.name, nodeCall_inputs));
            % call interpolation_using_prelookup
            if isempty(output_conv_format)
                body{(outIdx-1)*2+outIdx+1} = nasa_toLustre.lustreAst.LustreEq(outputs{outIdx}, ...
                    nasa_toLustre.lustreAst.NodeCallExpr(interpolationExtNode.name, solution_name{1}));
            else
                code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(output_conv_format, ...
                    nasa_toLustre.lustreAst.NodeCallExpr(interpolationExtNode.name, solution_name{1}));
                body{(outIdx-1)*2+outIdx+1} = nasa_toLustre.lustreAst.LustreEq(outputs{outIdx}, code);
            end
        else
            % call prelookup
            body{outIdx} = nasa_toLustre.lustreAst.LustreEq(prelookup_out, ...
                nasa_toLustre.lustreAst.NodeCallExpr(preLookUpExtNode.name, nodeCall_inputs));
            % call interpolation_using_prelookup
            if isempty(output_conv_format)
                body{(outIdx-1)*2+outIdx+1} = nasa_toLustre.lustreAst.LustreEq(outputs{outIdx}, ...
                    nasa_toLustre.lustreAst.NodeCallExpr(interpolationExtNode.name, prelookup_out));
            else
                code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(output_conv_format, ...
                    nasa_toLustre.lustreAst.NodeCallExpr(interpolationExtNode.name, prelookup_out));
                body{(outIdx-1)*2+outIdx+1} = nasa_toLustre.lustreAst.LustreEq(outputs{outIdx}, code);
            end
        end
    end

    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(node_header.NodeName)
    extNode.setInputs(node_header.Inputs);
    extNode.setOutputs( node_header.Outputs);
    extNode.setLocalVars(vars);
    extNode.setBodyEqs(body);
    extNode.setMetaInfo('external node code for doing PreLookup');

end

