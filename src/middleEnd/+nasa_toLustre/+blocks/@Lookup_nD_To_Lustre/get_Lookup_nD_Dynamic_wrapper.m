function extNode = get_Lookup_nD_Dynamic_wrapper(blkParams,inputs,...
    preLookUpExtNode,interpolationExtNode)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Lookup_nD
         
    % node header
    wrapper_header.NodeName = sprintf('%s_Lookup_wrapper_node',...
        blkParams.blk_name);
    % node header inputs
    wrapper_header.inputs = preLookUpExtNode.inputs;
    if LookupType.isLookupDynamic(blkParams.lookupTableType)
        numTableData = numel(inputs{3});
        for i=1:numTableData
            wrapper_header.inputs{end+1} = interpolationExtNode.inputs{...
                numel(interpolationExtNode.inputs)-numTableData+i};
        end
    end
    % node outputs, only y_out
    wrapper_header.output = interpolationExtNode.outputs; 
    
    % Declare variables for Pre look up outputs
    vars = preLookUpExtNode.outputs;    
    
    % call prelookup
    pre_outputs = ...
        cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.id),...
        preLookUpExtNode.outputs,'UniformOutput',false);
    pre_inputs = ...
        cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.id),...
        preLookUpExtNode.inputs,'UniformOutput',false);
    body{1} = ...
        nasa_toLustre.lustreAst.LustreEq(pre_outputs, ...
        nasa_toLustre.lustreAst.NodeCallExpr(...
        preLookUpExtNode.name, pre_inputs));
    % call interpolation_using_prelookup
    interp_outputs = ...
        cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.id),...
        interpolationExtNode.outputs,'UniformOutput',false);
    interp_inputs = ...
        cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.id),...
        interpolationExtNode.inputs,'UniformOutput',false);    
%     if isempty(output_conv_format)
    node_call_expr = nasa_toLustre.lustreAst.NodeCallExpr(...
        interpolationExtNode.name, interp_inputs);
%     else
%         node_call_expr = ...
%             nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
%             output_conv_format, nasa_toLustre.lustreAst.NodeCallExpr(...
%             interpolationExtNode.name, interp_inputs));
%     end
    body{2} = ...
        nasa_toLustre.lustreAst.LustreEq(interp_outputs, node_call_expr);

    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(wrapper_header.NodeName)
    extNode.setInputs(wrapper_header.inputs);
    extNode.setOutputs( wrapper_header.output);
    extNode.setLocalVars(vars);
    extNode.setBodyEqs(body);

end

