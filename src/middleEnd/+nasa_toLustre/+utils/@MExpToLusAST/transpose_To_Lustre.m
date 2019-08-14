function [code, exp_dt, dim, extra_code] = transpose_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isfield(tree, 'leftExp')
    [x, exp_dt, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.leftExp, args);
    else
        [x, exp_dt, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
        tree.parameters(1), args);
    end
    if isrow(x), x = x'; end
    x_reshp = reshape(x, x_dim);
    code = reshape(x_reshp', [prod(x_dim) 1]);
    dim = [x_dim(2) x_dim(1)];
    
end

