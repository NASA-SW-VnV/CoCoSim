function [code, exp_dt, dim] = cumsumFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    reverse = false;
    dimension = 1;
    code = {};
    op = nasa_toLustre.lustreAst.BinaryExpr.PLUS;
    
    [x, exp_dt, dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1), parent,...
        blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun);
    
    if length(dim) > 2 % TODO support multi-dimension input
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function cumsum in expression "%s" first argument is %d-dimension, more than 2 is not supported.',...
            tree.text, numel(x_dim));
        throw(ME);
    end
    
    if dim(1) == 1
        dimension = 2;
    end
    
    if length(tree.parameters) > 1
        if strcmp(tree.parameters{2}.type, 'String')
            reverse = strcmp(tree.parameters{2}.value, '''reverse''');
        else
            [y, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(2), parent,...
                blk, data_map, inputs, 'int', isSimulink, isStateFlow, isMatlabFun);
            dimension = y{1}.value;
        end
    end
    
    if length(tree.parameters) > 2
        reverse = strcmp(tree.parameters{3}.value, '''reverse''');
    end
    
    x_reshape = reshape(x, dim);
    
    if reverse
        if dimension == 1
            for i=1:dim(1)
                for j=1:dim(2)
                    code{i, j} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_reshape(i:end, j));
                end
            end
        else
            for i=1:dim(1)
                for j=1:dim(2)
                    code{i, j} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_reshape(i, j:end));
                end
            end
        end
    else
        if dimension == 1
            for i=1:dim(1)
                for j=1:dim(2)
                    code{i, j} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_reshape(1:i, j));
                end
            end
        else
            for i=1:dim(1)
                for j=1:dim(2)
                    code{i, j} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x_reshape(i, 1:j));
                end
            end
        end
    end
    
    code = reshape(code, [1 prod(dim)]);
    
end


