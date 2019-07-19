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
        [code, exp_dt, dim] = allAnyFun_To_Lustre(tree, args, op)
        
        [code, exp_dt, dim] = binaryFun_To_Lustre(tree, args, op)
        
        [code, dim] = mtimesFun_To_Lustre(x, x_dim, y, y_dim)
        
        [code, exp_dt, dim] = numFun_To_Lustre(tree, args, num)
    end
end

