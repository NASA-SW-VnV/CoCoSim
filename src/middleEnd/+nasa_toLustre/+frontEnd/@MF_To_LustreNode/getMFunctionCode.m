function [main_node, external_nodes, failed] = getMFunctionCode(blkObj, parent,  blk, Inputs, Outputs)
    %GETMFUNCTIONCODE
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    external_nodes ={};
    main_node = {};
    % get all user functions needed in one script
    [script, failed] = MF_To_LustreNode.getAllRequiredFunctionsInOneScript(blk );
    if failed, return; end
    % get all functions IR
    [functions, failed] = MF_To_LustreNode.getFunctionList(blk, script);
    if failed, return; end
    
    if isempty(functions)
        display_msg(sprintf('Parser failed for Matlab function in block %s. No function has been found.', ...
                HtmlItem.addOpenCmd(blk.Origin_path)),...
                MsgType.WARNING, 'getMFunctionCode', '');
        failed = 1;
        return;
%     elseif numel(functions) > 1
%         func_names = cellfun(@(x) x.name, functions, 'UniformOutput', 0);
%         %TODO: Work on progress to support more than one function definition.
%         display_msg(sprintf(['Matlab Function in block "%s" calls user-defined functions: "%s".\n'...
%             'Currently this compiler supports only one Matlab file and one function per file.'...
%             ' This block will be abstracted.'], ...
%             HtmlItem.addOpenCmd(blk.Origin_path), MatlabUtils.strjoin(func_names, ', ')), ...
%             MsgType.WARNING, 'getMFunctionCode', '');
%         failed = true;
%         return;
    end
    % creat DATA_MAP
    [fun_data_map, failed] = MF_To_LustreNode.getFuncsDataMap(blk, script, functions, Inputs, Outputs);
    if failed, return; end
    external_nodes ={};
    for i=1:length(functions)
        if isKey(fun_data_map, functions{i}.name)
            data_map = fun_data_map(functions{i}.name);
        else
            data_map = containers.Map;
        end
        [fun_node, failed_i ] = MF_To_LustreNode.getFuncCode(functions{i},...
            data_map, blkObj, parent, blk);
        failed = failed || failed_i;
        if i==1
            main_node = fun_node;
        elseif ~isempty(fun_node)
            external_nodes{end+1} = fun_node;
        end
    end
end


