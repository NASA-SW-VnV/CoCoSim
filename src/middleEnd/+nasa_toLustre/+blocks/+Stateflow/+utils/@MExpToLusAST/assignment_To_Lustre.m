function [code, assignment_dt] = assignment_To_Lustre(BlkObj, tree, parent, blk, ...
        data_map, inputs, ~, isSimulink, isStateFlow)
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    
    assignment_dt = MExpToLusDT.expression_DT(tree, data_map, inputs, isSimulink, isStateFlow);
    %     if isequal(tree.leftExp.type, 'fun_indexing') ...
    %             && ~isequal(tree.leftExp.parameters.type, 'constant')
    %         %TODO: we can creat all vector value
    %         %e.g. u(index) = exp
    %         % u_1 = if index = 1 then exp else u_1;
    %         % u_2 = if index = 2 then exp else u_2;
    %         ME = MException('COCOSIM:TREE2CODE', ...
    %             'Array index on the left hand of the expression "%s" should be a constant.',...
    %             tree.text);
    %         throw(ME);
    %     end
    left = MExpToLusAST.expression_To_Lustre(BlkObj, tree.leftExp, ...
        parent, blk, data_map, inputs, assignment_dt,...
        isSimulink, isStateFlow);
    
    right = MExpToLusAST.expression_To_Lustre(BlkObj, tree.rightExp, parent, blk,...
        data_map, inputs, assignment_dt, isSimulink, isStateFlow);
    if isequal(tree.leftExp.type, 'fun_indexing') ...
            && ~isequal(tree.leftExp.parameters.type, 'constant')
        [code, status] = ArrayIndexNotConstant(left, right, tree);
        if status
            ME = MException('COCOSIM:TREE2CODE', ...
                'Array index on the left hand of the expression "%s" should be a constant.',...
                tree.text);
            throw(ME);
        end
        return;
    end
    if isequal(tree.leftExp.type, 'matrix') && numel(right) == 1
        %e.g. [z,y] = f(x)
        left{1} = TupleExpr(left);
    elseif  numel(left) ~= numel(right)
        ME = MException('COCOSIM:TREE2CODE', ...
            'Assignement "%s" has incompatible dimensions. Left width is %d where the right width is %d',...
            tree.text, numel(left), numel(right));
        throw(ME);
    end
    if numel(left) > 1
        eqts = cell(numel(left), 1);
        for i=1:numel(left)
            eqts{i} = LustreEq(left{i}, right{i});
        end
        code{1} = ConcurrentAssignments(eqts);
    else
        code{1} =  LustreEq(left{1}, right{1});
    end
    
end

function [code, status] = ArrayIndexNotConstant(left, right, tree)
    %e.g. u(index) = exp
    % u_1 = if index = 1 then exp else u_1;
    % u_2 = if index = 2 then exp else u_2;
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    status = 0;
    code = {};
    [left, right] = MExpToLusAST.inlineOperands(left, right, tree);
    eqts = {};
    for i=1:numel(left)
        [conds, thens] = IteExpr.getCondsThens(left{i});
        if isempty(conds)
            eqts{end+1} = LustreEq(left{i}, right{i});
        else
            new_thens = thens;
            for j=1:numel(new_thens)
                [varId, status] = getVarID(new_thens{j});
                if status
                    return;
                end
                % replace varId by the right expression
                if numel(conds) >= j
                    c = conds{j};
                else
                    c = nasa_toLustre.lustreAst.UnaryExpr(UnaryExpr.NOT, ...
                        BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, conds));
                end
                eqts{end+1} = LustreEq(varId, IteExpr(c, right{i}, varId));
            end
        end
    end
    code{1} = ConcurrentAssignments(eqts);
end

function [varId, status] = getVarID(then)
    import nasa_toLustre.lustreAst.*
    status = 0;
    varId = {};
    if isa(then, 'ParenthesesExpr')
        [varId, status] = getVarID(then.getExp());
    elseif isa(then, 'VarIdExpr')
        varId = then;
    else
        status = 1;
    end
end