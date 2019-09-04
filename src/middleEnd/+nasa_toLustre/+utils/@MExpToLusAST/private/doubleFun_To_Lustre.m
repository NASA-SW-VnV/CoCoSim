function [code, exp_dt, dim, extra_code] = doubleFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [code, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.parameters(1), args);    
    [code, exp_dt] = nasa_toLustre.utils.MExpToLusDT.convertDT(args.blkObj, code, exp_dt, 'real');
end

