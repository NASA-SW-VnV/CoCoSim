function [first_arg, second_arg, m, n, y, perm, pre_exp, extra_code] = trapzUtil(tree, args)

%    
    
    perm = [];
    pre_exp = "";
    [x, ~, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    x = reshape(x, x_dim);
    if isa(tree.parameters, 'struct')
        params = arrayfun(@(x) x, tree.parameters, 'UniformOutput', 0);
    else
        params = tree.parameters;
    end
    if length(tree.parameters) >= 2
        [y, ~, y_dim, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2), args);
        extra_code = MatlabUtils.concat(extra_code, extra_code_i);
        y = reshape(y, y_dim);
        second_arg = params{2}.text;
    end
    if length(tree.parameters) >= 3
        [dimension, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(3), args);
        extra_code = MatlabUtils.concat(extra_code, extra_code_i);
    end
    
    if length(tree.parameters) == 3 % cumtrapz(x, y, dim)
        if ~isa(dimension{1}, 'nasa_toLustre.lustreAst.RealExpr') && ...
                ~isa(dimension{1}, 'nasa_toLustre.lustreAst.IntExpr')
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function cumtrapz in expression "%s" third argument must be a constant',...
                tree.text);
            throw(ME);
        end
        dimension = min(length(y_dim)+1, dimension{1}.value);
        perm_str = sprintf("[%d:%d, 1:%d]", dimension, max(length(y_dim), dimension), dimension-1);
        pre_exp = sprintf("%s = permute(%s, %s);", second_arg, second_arg, perm_str);
        perm = [dimension:max(length(y_dim), dimension), 1:dimension-1];
        y = permute(y, perm);
        [m, n] = size(y);
        first_arg = params{1}.text;
    elseif length(tree.parameters) == 2 && prod(y_dim) == 1 % cumtrapz(x, dim)
        if ~isa(y{1}, 'nasa_toLustre.lustreAst.RealExpr') && ...
                ~isa(y{1}, 'nasa_toLustre.lustreAst.IntExpr')
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function cumtrapz in expression "%s" second argument must be a constant',...
                tree.text);
            throw(ME);
        end
        dimension = y{1}.value;
        y = x;
        y_dim = x_dim;
        second_arg = tree.parameters{1}.text;
        dimension = min(length(y_dim)+1, dimension);
        perm_str = sprintf("[%d:%d, 1:%d]", dimension, max(length(y_dim), dimension), dimension-1);
        pre_exp = sprintf("%s = permute(%s, %s);", second_arg, second_arg, perm_str);
        perm = [dimension:max(length(y_dim), dimension), 1:dimension-1];
        y = permute(y, perm);
        [m, n] = size(y);
        first_arg = sprintf('(1:%d)''', m);
    else % cumtrapz(y) or cumtrapz(x,y)
        if length(tree.parameters) < 2
            y = x;
            second_arg = tree.parameters.text;
            [y,nshifts] = shiftdim(y);
            [m, n] = size(y);
            first_arg = sprintf('(1:%d)''', m);
        else
            [y,nshifts] = shiftdim(y);
            [m, n] = size(y);
            first_arg = params{1}.text;
        end
        
        dimension = nshifts + 1;
    end
    
    
end