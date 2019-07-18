function [code, exp_dt, dim] = zerosFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [code, exp_dt, dim] = nasa_toLustre.blocks.Stateflow.utils.MF2LusUtils.numFun_To_Lustre(...
        BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, ...
        isStateFlow, isMatlabFun, 0);
end

