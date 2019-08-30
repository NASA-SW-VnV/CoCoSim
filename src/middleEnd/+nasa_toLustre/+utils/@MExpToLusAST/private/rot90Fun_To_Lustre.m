function [code, exp_dt, dim, extra_code] = rot90Fun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    N = 1;
    [X, exp_dt, X_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    X = reshape(X, X_dim);
    
    if (length(tree.parameters) > 1)
        args.expected_lusDT = 'int';
        [N, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2),args);
        extra_code = MatlabUtils.concat(extra_code, extra_code_i);
        if isempty(N) || (~isa(N{1}, 'nasa_toLustre.lustreAst.IntExpr'))
            ME = MException('COCOSIM:TREE2CODE', ...
                'Second argument in function rot90 in expression "%s" should be a constant.',...
                tree.text);
            throw(ME);
        end
        N = N{1}.value;
    end
    code = rot90(X, N);
    dim = size(code);
    code = reshape(code, [prod(dim), 1]);
end
