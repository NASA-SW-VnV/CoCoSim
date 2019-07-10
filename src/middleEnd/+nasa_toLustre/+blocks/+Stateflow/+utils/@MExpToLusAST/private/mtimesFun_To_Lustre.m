function [code, exp_dt, dim] = mtimesFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [x, x_dt, x_dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
        parent, blk, data_map, inputs, expected_dt, ...
        isSimulink, isStateFlow, isMatlabFun);
    [y, ~, y_dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(2),...
        parent, blk, data_map, inputs, expected_dt, ...
        isSimulink, isStateFlow, isMatlabFun);
    
    [code, dim] = nasa_toLustre.blocks.Stateflow.utils.MF2LusUtils.mtimesFun_To_Lustre(x, x_dim, y, y_dim);
    
    exp_dt = x_dt;
    
end

