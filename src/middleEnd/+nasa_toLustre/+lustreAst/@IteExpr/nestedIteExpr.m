function exp = nestedIteExpr(conds, thens)

    if numel(thens) ~= numel(conds) + 1
        display_msg('Number of Thens expressions should be equal to Numbers of Conds + 1',...
            MsgType.ERROR, 'IteExpr.nestedIteExpr', '');
        exp = nasa_toLustre.lustreAst.VarIdExpr('');
        return;
    end
    if isempty(conds)
        exp = thens;
    elseif numel(conds) == 1
        if iscell(conds)
            c = conds{1};
        else
            c = conds;
        end
        exp = nasa_toLustre.lustreAst.IteExpr(c, thens{1}, thens{2});
    else
        % The recursive call takes a lot of time for |conds| > 1000
%         exp = nasa_toLustre.lustreAst.IteExpr(conds{1}, ...
%             thens{1}, ...
%             nasa_toLustre.lustreAst.IteExpr.nestedIteExpr( conds(2:end), thens(2:end)) ...
%             );
        
        % Solution 2: a loop
        nThens = length(thens);
        exp = thens{end};
        for i=(nThens-1):-1:1
            exp = nasa_toLustre.lustreAst.IteExpr(conds{i}, thens{i}, exp);
        end
    end
end
