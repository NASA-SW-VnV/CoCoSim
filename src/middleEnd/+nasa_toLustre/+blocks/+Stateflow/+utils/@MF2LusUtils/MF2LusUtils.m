classdef MF2LusUtils
    %MF2LUSUTILS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %         Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods(Static)
        [code, exp_dt, dim] = allAnyFun_To_Lustre(BlkObj, tree, parent, blk,...
            data_map, inputs, isSimulink, isStateFlow, isMatlabFun, op)
        
        [code, exp_dt, dim] = binaryFun_To_Lustre(BlkObj, tree, parent, blk,...
            data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun, op)
    end
end

