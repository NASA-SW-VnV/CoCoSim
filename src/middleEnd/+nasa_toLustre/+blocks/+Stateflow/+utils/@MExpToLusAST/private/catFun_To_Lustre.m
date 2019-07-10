function [code, exp_dt, dim] = catFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [n_dim, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
        parent, blk, data_map, inputs, expected_dt, ...
        isSimulink, isStateFlow, isMatlabFun);
    matrix = {};
    matrix_dim = {};
    for i=2:numel(tree.parameters)
        [matrix{end+1}, exp_dt, matrix_dim{end+1}] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(i),...
            parent, blk, data_map, inputs, expected_dt, ...
            isSimulink, isStateFlow, isMatlabFun);
    end
    matrix = arrayfun(@(i) reshape(matrix{i}, matrix_dim{i}), 1:numel(matrix), 'UniformOutput', 0);
    matrix = cat(n_dim{1}.value, matrix{:});
    code = reshape(matrix, [1 numel(matrix)]);
    dim = size(matrix);
    
end

