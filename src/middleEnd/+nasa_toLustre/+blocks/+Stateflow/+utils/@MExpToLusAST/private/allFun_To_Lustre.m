function [code, exp_dt, dim] = allFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% TODO all(X,DIM) works down the dimension DIM
    if length(tree.parameters) > 1
        ME = MException('COCOSIM:TREE2CODE', ...
            'Expression "%s" is not supported in Block %s.',...
            tree.text, blk.Origin_path);
        throw(ME);
    else
        [x, x_dt, dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
            parent, blk, data_map, inputs, 'bool', ...
            isSimulink, isStateFlow, isMatlabFun);
        if numel(dim) > 2 || (max(dim) ~= prod(dim))
            ME = MException('COCOSIM:TREE2CODE', ...
                'Expression "%s" is not supported in Block %s.',...
                tree.text, blk.Origin_path);
            throw(ME);
        end
        x = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.convertDT(BlkObj, x, x_dt, 'bool');
        op = nasa_toLustre.lustreAst.BinaryExpr.AND;
        
        code{1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(op, x);
        exp_dt = 'bool';
    end
end

