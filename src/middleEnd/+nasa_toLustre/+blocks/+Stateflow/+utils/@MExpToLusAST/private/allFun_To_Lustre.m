function [code, exp_dt] = allFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
            
    [x, x_dt] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
        parent, blk, data_map, inputs, 'bool', ...
        isSimulink, isStateFlow, isMatlabFun);
    x = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.convertDT(BlkObj, x, x_dt, 'bool');
    op = nasa_toLustre.lustreAst.BinaryExpr.AND;
    
    code{1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x);
    exp_dt = 'bool';
end

