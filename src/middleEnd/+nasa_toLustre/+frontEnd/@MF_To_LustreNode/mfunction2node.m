function [main_node, external_nodes ] = ...
        mfunction2node(blkObj, parent,  blk,  xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    external_nodes = {};
    main_node = {};
    % get Matlab Function parameters
    
    [blk, Inputs, Outputs] = MF_To_LustreNode.creatInportsOutports(blk);
    try
        % try translate Matlab code to Lustre if failed, it will be set as
        % imported
        [ fun_nodes, failed] = MF_To_LustreNode.getMFunctionCode(blkObj, parent,  blk, Inputs);
        main_node = fun_nodes{1};
        if length(fun_nodes) > 1
            external_nodes = fun_nodes(2:end);
        end
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'MF_To_LustreNode.mfunction2node', '');
        failed = true;
    end
    if failed
        % create an imported node
        is_main_node = false;
        isEnableORAction = false;
        isEnableAndTrigger = false;
        isContractBlk = false;
        isMatlabFunction = true;
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
        main_node.setIsImported(true);
        display_msg(sprintf('Matlab Function block "%s" will be abstracted', ...
            HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.WARNING, 'MF_To_LustreNode.mfunction2node', '');
    end
end