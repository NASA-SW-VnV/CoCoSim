function [code, exp_dt, dim] = numFun_To_Lustre(tree, args, num)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    expected_dt = args.expected_lusDT;
    args.expected_lusDT = 'int';
    [x, ~, x_dim] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.parameters(1), args);
    
    if strcmp(tree.parameters(1).dataType, 'String')
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function ones in expression "%s" does not support string input.',...
            tree.text);
        throw(ME);
    end
    
    dim = x{1}.value;
    if length(x_dim) > 1
        dim = arrayfun(@(i) x{i}.value, (1:prod(x_dim)));
    elseif length(tree.parameters) > 1
        for i=2:length(tree.parameters)
            [x, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.parameters(i),args);
            if strcmp(tree.parameters(i).dataType, 'String')
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Function ones in expression "%s" does not support string input.',...
                    tree.text);
                throw(ME);
            end
            dim = [dim x{1}.value];
        end
    end
    
    if strcmp(expected_dt, 'int')
        code = arrayfun(@(x) nasa_toLustre.lustreAst.IntExpr(num), (1:prod(dim)), 'UniformOutput', 0);
        exp_dt = 'int';
    else
        code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(num), (1:prod(dim)), 'UniformOutput', 0);
        exp_dt = 'real';
    end
    
end

