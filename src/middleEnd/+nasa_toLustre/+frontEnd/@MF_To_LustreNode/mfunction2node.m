function [main_node, external_nodes ] = ...
        mfunction2node(blkObj, parent,  blk,  xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    external_nodes = {};
    % get Matlab Function parameters
    is_main_node = false;
    isEnableORAction = false;
    isEnableAndTrigger = false;
    isContractBlk = false;
    isMatlabFunction = true;
    [blk, Inputs, Outputs] = MF_To_LustreNode.creatInportsOutports(blk);
    [node_name, node_inputs, node_outputs,...
        ~, ~] = ...
        nasa_toLustre.utils.SLX2LusUtils.extractNodeHeader(parent, blk, is_main_node,...
        isEnableORAction, isEnableAndTrigger, isContractBlk, isMatlabFunction, ...
        main_sampleTime, xml_trace);
    
    comment = LustreComment(...
        sprintf('Original block name: %s', blk.Origin_path), true);
    main_node = LustreNode(...
        comment, ...
        node_name,...
        node_inputs, ...
        node_outputs, ...
        {}, ...
        {}, ...
        {}, ...
        false);
    
    try
        % try translate Matlab code to Lustre if failed, it will be set as
        % imported
        [body, variables, failed] = MF_To_LustreNode.getMFunctionCode(blkObj, parent,  blk, Inputs, Outputs);
        if failed
            main_node.setIsImported(true);
            display_msg(sprintf('Matlab Function block "%s" will be abstracted', ...
                HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.WARNING, 'MF_To_LustreNode.mfunction2node', '');
        else
            main_node.setBodyEqs(body);
            
            % For matlab no Id is used in names because of Function internal vars
            Inputs = cellfun(@(x) rmfield(x, 'Id'), Inputs, 'UniformOutput', 0);
            Outputs = cellfun(@(x) rmfield(x, 'Id'), Outputs, 'UniformOutput', 0);
            inputs = SF2LusUtils.getDataVars(...
                SF2LusUtils.orderObjects(Inputs, 'Port'));
            outputs = SF2LusUtils.getDataVars(...
                SF2LusUtils.orderObjects(Outputs, 'Port'));
            variables = LustreVar.uniqueVars(variables);
            variables = LustreVar.setDiff(variables, outputs);
            main_node.setInputs(inputs);
            main_node.setOutputs(outputs);
            main_node.setLocalVars(variables);
            main_node = main_node.pseudoCode2Lustre();
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'MF_To_LustreNode.mfunction2node', '');
        display_msg(sprintf('Matlab Function block "%s" will be abstracted', ...
            HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.WARNING, 'MF_To_LustreNode.mfunction2node', '');
        main_node.setIsImported(true);
    end
    
end