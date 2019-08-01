function [external_nodes, failed] = getMFunctionCode(blkObj, parent,  blk, Inputs)
    %GETMFUNCTIONCODE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %
    %
    global SF_MF_FUNCTIONS_MAP MFUNCTION_EXTERNAL_NODES
    % reset MFUNCTION_EXTERNAL_NODES
    MFUNCTION_EXTERNAL_NODES = {};
    external_nodes ={};
    % get all user functions needed in one script
    [script, failed] = nasa_toLustre.frontEnd.MF_To_LustreNode.getAllRequiredFunctionsInOneScript(blk );
    if failed, return; end
    % get all functions IR
    [funcList, failed] = nasa_toLustre.frontEnd.MF_To_LustreNode.getFunctionList(blk, script);
    if failed, return; end
    
    if isempty(funcList)
        display_msg(sprintf('Parser failed for Matlab function in block %s. No function has been found.', ...
            HtmlItem.addOpenCmd(blk.Origin_path)),...
            MsgType.WARNING, 'getMFunctionCode', '');
        failed = 1;
        return;
    end
    
    % creat DATA_MAP
    [fun_data_map, failed] = nasa_toLustre.frontEnd.MF_To_LustreNode.getFuncsDataMap(blk, script, ...
        funcList, Inputs);
    if failed, return; end
    
    % Get all functions information before generating code
    func_nodes = cellfun(@(func) nasa_toLustre.frontEnd.MF_To_LustreNode.getFunHeader(func, blk, fun_data_map(func.name)), ...
        funcList, 'UniformOutput', 0);
    func_names = cellfun(@(func) func.name, funcList, 'UniformOutput', 0);
    SF_MF_FUNCTIONS_MAP = containers.Map(func_names, func_nodes);
    
    %generate code
    [external_nodes, failed] = cellfun(@(func) ...
        nasa_toLustre.frontEnd.MF_To_LustreNode.getFuncCode(func, fun_data_map(func.name), blkObj, parent, blk), ...
        funcList, 'UniformOutput', 0);
    failed = all([failed{:}]);
    if ~isempty(MFUNCTION_EXTERNAL_NODES)
        external_nodes = MatlabUtils.concat(external_nodes, MFUNCTION_EXTERNAL_NODES);
    end
end


