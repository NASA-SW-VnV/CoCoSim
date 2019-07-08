function [code, exp_dt, dim] = allFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %         Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    op = nasa_toLustre.lustreAst.BinaryExpr.AND;
    [code, exp_dt, dim] = nasa_toLustre.blocks.Stateflow.utils.MF2LusUtils.allAnyFun_To_Lustre(...
        BlkObj, tree, parent, blk,...
        data_map, inputs, isSimulink, isStateFlow, isMatlabFun, op);
end
