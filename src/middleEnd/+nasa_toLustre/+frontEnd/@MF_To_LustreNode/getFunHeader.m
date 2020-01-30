function [fun_node] = getFunHeader(func, blk, data_map)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %
    
    data_set = data_map.values(); 
    data_set = data_set(cellfun(@(x) isstruct(x), data_set));
    scopes = cellfun(@(x) x.Scope, data_set, 'UniformOutput', 0);
    Inputs = data_set(strcmp(scopes, 'Input'));
    Outputs = data_set(strcmp(scopes, 'Output'));
    node_inputs = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataVars(...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(Inputs, 'Port'));
    node_outputs = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getDataVars(...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(Outputs, 'Port'));
    blk_name = nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Function %s inside Matlab Function block: %s',func.name, blk.Origin_path), true);
    node_name = strcat(blk_name, '_', func.name);
    if isempty(node_inputs)
        node_inputs{1} = nasa_toLustre.lustreAst.LustreVar('_virtual', 'bool');
    end
    fun_node = nasa_toLustre.lustreAst.LustreNode(...
        comment, ...
        node_name,...
        node_inputs, ...
        node_outputs, ...
        {}, ...
        {}, ...
        {}, ...
        false);
end

