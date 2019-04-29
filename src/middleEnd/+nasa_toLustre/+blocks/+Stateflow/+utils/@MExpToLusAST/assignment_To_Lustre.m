function [code, assignment_dt] = assignment_To_Lustre(BlkObj, tree, parent, blk, ...
        data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
            
    assignment_dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    left = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.leftExp, ...
        parent, blk, data_map, inputs, assignment_dt,...
        isSimulink, isStateFlow, isMatlabFun);
    
    right = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.rightExp, parent, blk,...
        data_map, inputs, assignment_dt, isSimulink, isStateFlow, isMatlabFun);
    if strcmp(tree.leftExp.type, 'fun_indexing') ...
            && ~strcmp(tree.leftExp.parameters.type, 'constant')
        [code, status] = ArrayIndexNotConstant(left, right, tree);
        if status
            ME = MException('COCOSIM:TREE2CODE', ...
                'Array index on the left hand of the expression "%s" should be a constant.',...
                tree.text);
            throw(ME);
        end
        return;
    end
    if strcmp(tree.leftExp.type, 'matrix') && numel(right) == 1
        %e.g. [z,y] = f(x)
        left{1} = nasa_toLustre.lustreAst.TupleExpr(left);
    elseif  numel(left) ~= numel(right)
        ME = MException('COCOSIM:TREE2CODE', ...
            'Assignement "%s" has incompatible dimensions. Left width is %d where the right width is %d',...
            tree.text, numel(left), numel(right));
        throw(ME);
    end
    if numel(left) > 1
        eqts = cell(numel(left), 1);
        for i=1:numel(left)
            eqts{i} = nasa_toLustre.lustreAst.LustreEq(left{i}, right{i});
        end
        code{1} = nasa_toLustre.lustreAst.ConcurrentAssignments(eqts);
    else
        code{1} =  nasa_toLustre.lustreAst.LustreEq(left{1}, right{1});
    end
    
end

function [code, status] = ArrayIndexNotConstant(left, right, tree)
    %e.g. u(index) = exp
    % u_1 = if index = 1 then exp else u_1;
    % u_2 = if index = 2 then exp else u_2;
            status = 0;
    code = {};
    [left, right] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.inlineOperands(left, right, tree);
    eqts = {};
    for i=1:numel(left)
        [conds, thens] = nasa_toLustre.lustreAst.IteExpr.getCondsThens(left{i});
        if isempty(conds)
            eqts{end+1} = nasa_toLustre.lustreAst.LustreEq(left{i}, right{i});
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
                    c = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, ...
                        nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.OR, conds));
                end
                eqts{end+1} = nasa_toLustre.lustreAst.LustreEq(varId, nasa_toLustre.lustreAst.IteExpr(c, right{i}, varId));
            end
        end
    end
    code{1} = nasa_toLustre.lustreAst.ConcurrentAssignments(eqts);
end

function [varId, status] = getVarID(then)
    status = 0;
    varId = {};
    if isa(then, 'nasa_toLustre.lustreAst.ParenthesesExpr')
        [varId, status] = getVarID(then.getExp());
    elseif isa(then, 'nasa_toLustre.lustreAst.VarIdExpr')
        varId = then;
    else
        status = 1;
    end
end
