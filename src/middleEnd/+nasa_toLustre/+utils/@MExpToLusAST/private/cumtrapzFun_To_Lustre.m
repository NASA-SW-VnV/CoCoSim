function [code, exp_dt, dim, extra_code] = cumtrapzFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    [first_arg, second_arg, m, n, y, perm, pre_exp, extra_code] = ...
        nasa_toLustre.utils.MF2LusUtils.trapzUtil(tree, args);
    
    siz = size(y);
    
    if m >= 2
        left_exp = sprintf("[zeros(1, %d); ", n);
        dt_exp = sprintf("repmat(diff(%s,1,1)/2,1,%d)", first_arg, n);
        right_exp = sprintf("cumsum(%s .* (%s(1:%d,1:%d) + %s(2:%d,1:%d)), 1)];", ...
            dt_exp, second_arg, m-1, size(y,2), second_arg, m, size(y,2));
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
    exp_dt = 'real';
    
    if ~strcmp(pre_exp, "")
        pre_tree = MatlabUtils.getExpTree(pre_exp);
        pre_code = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(pre_tree, args);
        extra_code = MatlabUtils.concat(extra_code, pre_code);
    end
    
    
end