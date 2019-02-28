function [code, exp_dt] = anyFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    import nasa_toLustre.utils.SLX2LusUtils
    [x, x_dt] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
        parent, blk, data_map, inputs, 'bool', ...
        isSimulink, isStateFlow, isMatlabFun);
    x = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.convertDT(BlkObj, x, x_dt, 'bool');
    op = nasa_toLustre.lustreAst.BinaryExpr.OR;
    code{1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x);
    exp_dt = 'bool';
end

