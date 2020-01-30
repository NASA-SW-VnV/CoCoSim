function [lusDT, slxDT] = unaryExpression_DT(tree, args)

    
    %unaryExpression_DT for unaryOperator :  '&' | '*' | '+' | '-' | '~' | '!'
    
    if strcmp(tree.operator, '~') || strcmp(tree.operator, '!')
        lusDT = 'bool';
        slxDT = 'boolean';
    else
        [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree.rightExp, args);
    end
end

