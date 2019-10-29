function [code, exp_dt, dim, extra_code] = maxFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    op = nasa_toLustre.lustreAst.BinaryExpr.GTE;
    [code, exp_dt, dim, extra_code] = nasa_toLustre.utils.MF2LusUtils.maxMinFun_To_Lustre(...
        tree, args, op);
end