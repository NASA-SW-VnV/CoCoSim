function [code, exp_dt, dim] = sumFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    op = nasa_toLustre.lustreAst.BinaryExpr.PLUS;
    if length(tree.parameters) == 1
        [x, x_dt, dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
            parent, blk, data_map, inputs, expected_dt, ...
            isSimulink, isStateFlow, isMatlabFun);
        code{1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x);
        if numel(dim) > 2 || (max(dim) ~= prod(dim))
            ME = MException('COCOSIM:TREE2CODE', ...
                'Expression "%s" is not supported in Block %s.',...
                tree.text, blk.Origin_path);
            throw(ME);
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

