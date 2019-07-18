function [code, exp_dt, dim] = colonExpression_To_Lustre(BlkObj, tree, parent,...
        blk, data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if strcmp(tree.operator, ':end')
        msg = sprintf('Expression "%s" in block "%s" is not supported: Colon indexing without constant is not supported',...
            tree.text, HtmlItem.addOpenCmd(blk.Origin_path));
        ME = MException('COCOSIM:TREE2CODE', msg);
        throw(ME);
    end
    
    if ~isfield(tree, 'leftExp') || ~isfield(tree, 'rightExp')
        ME = MException('COCOSIM:TREE2CODE', ...
            'Colon indexing without constant is not supported');
        throw(ME);
    end
    if count(tree.text, ':') == 2
        if strcmp(tree.leftExp.leftExp.type, 'constant') && strcmp(tree.leftExp.rightExp.type, 'constant') && strcmp(tree.rightExp.type, 'constant')
            [left, left_dt, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.leftExp.leftExp,...
                parent, blk, data_map, inputs, expected_dt, ...
                isSimulink, isStateFlow, isMatlabFun);
            [middle, middle_dt, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.leftExp.rightExp,...
                parent, blk, data_map, inputs, expected_dt, ...
                isSimulink, isStateFlow, isMatlabFun);
            [right, right_dt, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.rightExp,...
                parent, blk, data_map, inputs, expected_dt, ...
                isSimulink, isStateFlow, isMatlabFun);
            upper_dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.upperDT(left_dt, right_dt);
            exp_dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.upperDT(upper_dt, middle_dt);
            left_value = left{1}.value;
            middle_value = middle{1}.value;
            right_value = right{1}.value;
            if strcmp(exp_dt, 'int')
                code = arrayfun(@(x) nasa_toLustre.lustreAst.IntExpr(x), (left_value:middle_value:right_value), 'UniformOutput', 0);
            else
                code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(x), (left_value:middle_value:right_value), 'UniformOutput', 0);
            end
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function in expression "%s" only support constant input',...
                tree.text, numel(Y));
            throw(ME);
        end
        
    elseif count(tree.text, ':') == 1
        [left, left_dt, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.leftExp,...
            parent, blk, data_map, inputs, expected_dt, ...
            isSimulink, isStateFlow, isMatlabFun);
        [right, right_dt, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.rightExp,...
            parent, blk, data_map, inputs, expected_dt, ...
            isSimulink, isStateFlow, isMatlabFun);
        exp_dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.upperDT(left_dt, right_dt);
        left_value = left{1}.value;
        right_value = right{1}.value;
        if strcmp(exp_dt, 'int')
            code = arrayfun(@(x) nasa_toLustre.lustreAst.IntExpr(x), (left_value:right_value), 'UniformOutput', 0);
        else
            code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(x), (left_value:right_value), 'UniformOutput', 0);
        end
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function in expression "%s" is not supported.',...
            tree.text, numel(Y));
        throw(ME);
    end
    dim = [1 numel(code)];
end

