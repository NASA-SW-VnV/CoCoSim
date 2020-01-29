function [code, exp_dt, dim, extra_code] = permuteFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    [X, X_dt, X_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    args.expected_lusDT = 'int';
    [Y, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2),args);
    extra_code = MatlabUtils.concat(extra_code, extra_code_i);
    X_reshp = reshape(X, X_dim);
    if isempty(Y) || (~isa(Y{1}, 'nasa_toLustre.lustreAst.RealExpr') ...
            && ~isa(Y{1}, 'nasa_toLustre.lustreAst.IntExpr'))
         ME = MException('COCOSIM:TREE2CODE', ...
            'Second argument in function permute in expression "%s" should be a constant.',...
            tree.text);
        throw(ME);
    end
    
    code = permute(X_reshp, str2num(tree.parameters{2}.text));
    exp_dt = X_dt;
    dim = size(code);
    code = reshape(code, [prod(X_dim) 1]);
end

