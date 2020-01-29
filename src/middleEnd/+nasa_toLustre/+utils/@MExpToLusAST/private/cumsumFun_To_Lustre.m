function [code, exp_dt, dim, extra_code] = cumsumFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    reverse = false;
    dimension = 1;
    code = {};
    extra_code = {};
    op = nasa_toLustre.lustreAst.BinaryExpr.PLUS;
    [x, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
    if isrow(x), x = x'; end

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
            args.expected_lusDT = 'int';
            [y, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2), args);
            extra_code = MatlabUtils.concat(extra_code, extra_code_i);
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
    
    code = reshape(code, [prod(dim) 1]);
    
end


