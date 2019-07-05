function [code, exp_dt, dim] = sumFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    code = {};
    op = nasa_toLustre.lustreAst.BinaryExpr.PLUS;
    if length(tree.parameters) == 1
        [x, x_dt, dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
            parent, blk, data_map, inputs, expected_dt, ...
            isSimulink, isStateFlow, isMatlabFun);
        n_dim = numel(dim);
        if n_dim > 2
            ME = MException('COCOSIM:TREE2CODE', ...
            'Function sum in expression "%s" first argument is %s-dimension, more than 2 is not supported.',...
            tree.text, numel(dim));
            throw(ME);
        elseif n_dim > 1
            x_new = reshape(x, dim);
            for i=1:dim(2)
                code{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_new(:,i));
            end
        else
            code{1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x);
        end
    else
        %TODO support "sum(X,DIM)" sums along the dimension DIM.
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function sum in expression "%s" has more than one argument is not supported.',...
            tree.text);
        throw(ME);
    end
    exp_dt = x_dt;
end

