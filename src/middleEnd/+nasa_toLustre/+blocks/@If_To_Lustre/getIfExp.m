
function IfExp = getIfExp(blk)
    IfExp{1} =  blk.IfExpression;
    elseExp = split(blk.ElseIfExpressions, ',');
    IfExp = [IfExp; elseExp];
    if strcmp(blk.ShowElse, 'on')
        IfExp{end+1} = '';
    end
end
