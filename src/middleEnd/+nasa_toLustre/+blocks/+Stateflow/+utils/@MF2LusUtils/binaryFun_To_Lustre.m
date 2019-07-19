function [code, exp_dt, dim] = binaryFun_To_Lustre(tree, args, op)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    code = {};
    [x, x_dt, x_dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    [y, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2), args);
    
    for i=1:numel(x)
        code{end+1} = nasa_toLustre.lustreAst.BinaryExpr(op, ...
            x(i), ...
            y(i),...
            false);
    end
    dim = x_dim;
    exp_dt = x_dt;
    
end