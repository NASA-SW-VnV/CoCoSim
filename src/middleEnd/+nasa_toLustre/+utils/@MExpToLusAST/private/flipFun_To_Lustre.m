function [code, exp_dt, dim, extra_code] = flipFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [X, X_dt, X_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    X_reshp = reshape(X, X_dim);
    
    if (length(tree.parameters) > 1)
        args.expected_lusDT = 'int';
        [Y, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2),args);
        extra_code = MatlabUtils.concat(extra_code, extra_code_i);
        if isempty(Y) || (~isa(Y{1}, 'nasa_toLustre.lustreAst.IntExpr'))
            ME = MException('COCOSIM:TREE2CODE', ...
                'Second argument in function flip in expression "%s" should be a constant.',...
                tree.text);
            throw(ME);
        end
        code1 = flip(X_reshp, Y{1}.value);
    else
        code1 = flip(X_reshp);
    end
    exp_dt = X_dt;
    dim = size(code1);
    code = reshape(code1, [prod(dim) 1]);
end

