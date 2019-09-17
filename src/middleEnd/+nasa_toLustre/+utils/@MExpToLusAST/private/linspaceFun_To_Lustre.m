function [code, exp_dt, dim, extra_code] = linspaceFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    args.expected_lusDT = 'real';
    N = 100;
    [X, ~, ~, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    [Y, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2),args);
    extra_code = MatlabUtils.concat(extra_code, extra_code_i);
    
    if isempty(X) || (~isa(X{1}, 'nasa_toLustre.lustreAst.RealExpr')) || ...
            isempty(Y) || (~isa(Y{1}, 'nasa_toLustre.lustreAst.RealExpr'))
        ME = MException('COCOSIM:TREE2CODE', ...
            'All argument in function linspace in expression "%s" should be a constant.',...
            tree.text);
        throw(ME);
    end
    
    if (length(tree.parameters) > 2)
        [N, ~, ~, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(3),args);
        extra_code = MatlabUtils.concat(extra_code, extra_code_i);
        if isempty(N) || (~isa(N{1}, 'nasa_toLustre.lustreAst.RealExpr'))
            ME = MException('COCOSIM:TREE2CODE', ...
                'Third argument in function linspace in expression "%s" should be a constant.',...
                tree.text);
            throw(ME);
        end
        N = N{1}.value;
    end
    
    pre_code = linspace(X{1}.value, Y{1}.value, N);
    code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(x), pre_code, 'UniformOutput', 0);
    
    exp_dt = 'real';
    dim = size(code);
end

