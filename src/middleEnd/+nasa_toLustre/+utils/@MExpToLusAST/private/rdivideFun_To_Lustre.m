function [code, exp_dt, dim, extra_code] = rdivideFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isa(tree.parameters, 'struct')
        params = arrayfun(@(i) tree.parameters(i), 1:length(tree.parameters), 'UniformOutput', 0);
    else
        params = tree.parameters;
    end
    
    x_text = params{1}.text;
    y_text = params{2}.text;
    
    expr = sprintf("(%s)./(%s)", x_text, y_text);
    new_tree = MatlabUtils.getExpTree(expr);
    
    [code, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(new_tree, args);
    
end