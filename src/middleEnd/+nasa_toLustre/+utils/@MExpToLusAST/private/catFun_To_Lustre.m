function [code, exp_dt, dim, extra_code] = catFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [n_dim, ~, ~, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    matrix = {};
    matrix_dim = {};
    for i=2:numel(tree.parameters)
        [matrix{end+1}, exp_dt, matrix_dim{end+1}, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(i),args);
        extra_code = MatlabUtils.concat(extra_code, extra_code_i);
    end
    matrix = arrayfun(@(i) reshape(matrix{i}, matrix_dim{i}), 1:numel(matrix), 'UniformOutput', 0);
    matrix = cat(n_dim{1}.value, matrix{:});
    code = reshape(matrix, [1 numel(matrix)]);
    dim = size(matrix);
    
end

