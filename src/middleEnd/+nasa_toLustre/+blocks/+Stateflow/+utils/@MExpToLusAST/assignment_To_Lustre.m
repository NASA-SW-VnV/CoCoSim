function [code, assignment_dt] = assignment_To_Lustre(BlkObj, tree, parent, blk, ...
        data_map, inputs, ~, isSimulink, isStateFlow)
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    
    assignment_dt = MExpToLusDT.expression_DT(tree, data_map, inputs, isSimulink, isStateFlow);
    if isequal(tree.leftExp.type, 'matrix')
        elts = tree.leftExp.rows{1};
        args = cell(numel(elts), 1);
        if ischar(assignment_dt)
            left_dt = arrayfun(@(i) assignment_dt, ...
                (1:numel(elts)), 'UniformOutput', false);
        elseif iscell(assignment_dt) && numel(assignment_dt) < numel(elts)
            left_dt = arrayfun(@(i) assignment_dt{1}, ...
                (1:numel(elts)), 'UniformOutput', false);
        else
            left_dt = assignment_dt;
        end
        for i=1:numel(elts)
            args(i) = ...
                MExpToLusAST.expression_To_Lustre(BlkObj, elts(i), ...
                parent, blk, data_map, inputs, left_dt{i},...
                isSimulink, isStateFlow);
        end
        left{1} = TupleExpr(args);
    else
        if isequal(tree.leftExp.type, 'fun_indexing') ...
                && ~isequal(tree.leftExp.parameters.type, 'constant')
            %TODO: we can creat all vector value
            %e.g. u(index) = exp
            % u_1 = if index = 1 then exp else u_1;
            % u_2 = if index = 2 then exp else u_2;
            ME = MException('COCOSIM:TREE2CODE', ...
                'Array index on the left hand of the expression "%s" should be a constant.',...
                tree.text);
            throw(ME);
        end
        left = MExpToLusAST.expression_To_Lustre(BlkObj, tree.leftExp, ...
            parent, blk, data_map, inputs, assignment_dt,...
            isSimulink, isStateFlow);
    end
    right = MExpToLusAST.expression_To_Lustre(BlkObj, tree.rightExp, parent, blk,...
        data_map, inputs, assignment_dt, isSimulink, isStateFlow);
    if numel(left) ~= numel(right)
        ME = MException('COCOSIM:TREE2CODE', ...
            'Assignement "%s" has incompatible dimensions. Left width is %d where the right width is %d',...
            tree.text, numel(left), numel(right));
        throw(ME);
    end
    code = cell(numel(left), 1);
    for i=1:numel(left)
        code{i} = LustreEq(left{i}, right{i});
    end
    
    
end