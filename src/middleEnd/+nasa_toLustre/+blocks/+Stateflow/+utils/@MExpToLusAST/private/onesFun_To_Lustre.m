function [code, exp_dt, dim] = onesFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [x, ~, x_dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
        parent, blk, data_map, inputs, 'int', ...
        isSimulink, isStateFlow, isMatlabFun);
    
    if strcmp(tree.parameters(1).dataType, 'String')
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function ones in expression "%s" does not support string input.',...
            tree.text);
        throw(ME);
    end
    
    dim = x{1}.value;
    if length(x_dim) > 1
        dim = arrayfun(@(i) x{i}.value, (1:prod(x_dim)));
    elseif length(tree.parameters) > 1
        for i=2:length(tree.parameters)
            [x, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(i),...
                parent, blk, data_map, inputs, 'int', ...
                isSimulink, isStateFlow, isMatlabFun);
            if strcmp(tree.parameters(i).dataType, 'String')
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Function ones in expression "%s" does not support string input.',...
                    tree.text);
                throw(ME);
            end
            dim = [dim x{1}.value];
        end
    end
    
    if strcmp(expected_dt, 'int')
        code = arrayfun(@(x) nasa_toLustre.lustreAst.IntExpr(1), (1:prod(dim)), 'UniformOutput', 0);
        exp_dt = 'int';
    else
        code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(1), (1:prod(dim)), 'UniformOutput', 0);
        exp_dt = 'real';
    end
    
end

