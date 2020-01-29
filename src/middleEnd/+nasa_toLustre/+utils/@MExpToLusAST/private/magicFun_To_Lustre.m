function [code, exp_dt, dim, extra_code] = magicFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    args.expected_lusDT = 'int';
    [X, ~, ~, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    
    if isempty(X) || (~isa(X{1}, 'nasa_toLustre.lustreAst.IntExpr'))
        ME = MException('COCOSIM:TREE2CODE', ...
            'First argument in function magic in expression "%s" should be a constant.',...
            tree.text);
        throw(ME);
    end
    
    pre_code = magic(X{1}.value);
    code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(x), pre_code, 'UniformOutput', 0);
    
    exp_dt = 'real';
    dim = size(code);
    code = reshape(code, [prod(dim) 1]);
end

