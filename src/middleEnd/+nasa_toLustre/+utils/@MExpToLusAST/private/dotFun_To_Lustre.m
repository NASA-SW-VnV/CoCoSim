function [code, exp_dt, dim, extra_code] = dotFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if length(tree.parameters) > 2
        % TODO support 3 parameters
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function dot in expression "%s" more than 2 arguments is not supported.',...
            tree.text);
        throw(ME);
    end
    
    x_text = tree.parameters(1).text;
    y_text = tree.parameters(2).text;
    
    expr = sprintf("sum(%s.*%s))", x_text, y_text);
    new_tree = MatlabUtils.getExpTree(expr);
    
    [code, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(new_tree, args);
end

