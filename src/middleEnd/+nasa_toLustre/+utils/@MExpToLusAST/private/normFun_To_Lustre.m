function [code, exp_dt, dim, extra_code] = normFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    dim = [1 1];
    x_text = tree.parameters(1).text;
    p_text = '2';
    if length(tree.parameters) > 1
        % TODO suppor second args
        %p_text = tree.parameters(u).text;
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function norm in expression "%s" do not support 2 arguments.',...
            tree.text, numel(x_dim));
        throw(ME);
    end
    expr = sprintf("sqrt(sum(abs(%s).^%s))", x_text, p_text);
    new_tree = MatlabUtils.getExpTree(expr);
    
    [code, exp_dt, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(new_tree, args);
    
end