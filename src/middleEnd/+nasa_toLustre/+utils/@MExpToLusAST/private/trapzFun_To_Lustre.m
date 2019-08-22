function [code, exp_dt, dim, extra_code] = trapzFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % The output size for [] is a special case when DIM is not given.
    
    
    code = {};
    perm = [];
    pre_exp = "";
    [x, x_dt, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    x = reshape(x, x_dim);
    if length(tree.parameters) >= 2
        [y, ~, y_dim, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2), args);
        extra_code = MatlabUtils.concat(extra_code, extra_code_i);
        y = reshape(y, y_dim);
        second_arg = tree.parameters{2}.text;
    end
    if length(tree.parameters) >= 3
        [dimension, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(3), args);
        extra_code = MatlabUtils.concat(extra_code, extra_code_i);
    end
    
    if length(tree.parameters) == 3 % trapz(x, y, dim)
        % TODO support this case by executing the permutation before
        dimension = min(length(y_dim)+1, dimension);
        perm_str = sprintf("[%d:%d, 1:%d]", dimension, max(length(y_dim), dimension), dimension-1);
        pre_exp = sprintf("%s = permute(%s, %s);", second_arg, second_arg, perm_str);
        perm = [dimension:max(length(y_dim), dimension), 1:dimension-1];
        y = permute(y, perm);
        m = size(y,1);
    elseif length(tree.parameters) == 2 && prod(y_dim) == 1 % trapz(x, dim)
        % TODO support this case by executing the permutation before
        if ~isa(y{1}, 'nasa_toLustre.lustreAst.RealExpr') && ...
                ~isa(y{1}, 'nasa_toLustre.lustreAst.IntExpr')
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function trapz in expression "%s" second argument must be a constant',...
                tree.text);
            throw(ME);
        end
        dimension = y{1}.value;
        y = x;
        y_dim = x_dim;
        second_arg = tree.parameters{1}.text;
        dimension = min(length(y_dim)+1, dimension);
        % TODO support this case
        perm_str = sprintf("[%d:%d, 1:%d]", dimension, max(length(y_dim), dimension), dimension-1);
        pre_exp = sprintf("%s = permute(%s, %s);", second_arg, second_arg, perm_str);
        perm = [dimension:max(length(y_dim), dimension), 1:dimension-1];
        y = permute(y, perm);
        m = size(y,1);
        first_arg = sprintf('(1:%d)''', m);
    else % trapz(y) or trapz(x,y)
        nshifts = 0;
        if length(tree.parameters) < 2
            y = x;
            y_dim = x_dim;
            second_arg = tree.parameters.text;
            [y,nshifts] = shiftdim(y);
            m = size(y,1);
            first_arg = sprintf('(1:%d)''', m);
        else
            m = size(y,1);
        end
        dimension = nshifts + 1;
    end
    
    if isempty(perm) && isempty(y)
        if isa(y{1}, 'nasa_toLustre.lustreAst.RealExpr')
            code{1} = nasa_toLustre.lustreAst.RealExpr('0');
        elseif isa(y{1}, 'nasa_toLustre.lustreAst.IntExpr')
            code{1} = nasa_toLustre.lustreAst.IntExpr('0');
        end
        dim = [1 1];
        return;
    end
    
    siz = size(y); siz(1) = 1;
    
    if m >= 2
        left_exp = sprintf("diff(%s, 1, 1).' * ", first_arg);
        right_exp = sprintf("(%s(1:%d,1:%d) + %s(2:%d,1:%d))/2", second_arg, ...
            m-1, size(y,2), second_arg, m, size(y,2));
        expr = strcat(left_exp, right_exp);
    else
        expr = "[";
        for i=1:siz(2)
            expr = strcat(expr, "0 ");
        end
        expr = strcat(expr, "]");
    end
    
    % second_arg have a new size with the permutation. So we have to modify
    % the data map before we call `expression_To_Lustre` and restore it
    % after that
    
    data_map = args.data_map;
    saved_var = data_map(second_arg);
    modified_var = data_map(second_arg);
    new_size = replace(replace(replace(mat2str(size(y)), ' ', '  '), '[', ''), ']', '');
    modified_var.ArraySize = new_size;
    modified_var.CompiledSize = new_size;
    args.data_map(second_arg) = modified_var;
    
    new_tree = MatlabUtils.getExpTree(expr);
    code = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(new_tree, args);
    
    % restore data map state
    args.data_map(second_arg) = saved_var;
    
    
    code = reshape(code,siz);
    if ~isempty(perm) && numel(code) > 1, code = ipermute(code,perm); end
    dim = siz;
    code = reshape(code, [prod(dim), 1]);
    exp_dt = x_dt;
    
    if ~strcmp(pre_exp, "")
        pre_tree = MatlabUtils.getExpTree(pre_exp);
        pre_code = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(pre_tree, args);
        extra_code = MatlabUtils.concat(extra_code, pre_code);
    end
    
    
end