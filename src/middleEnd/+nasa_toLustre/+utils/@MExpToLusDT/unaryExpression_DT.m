function [lusDT, slxDT] = unaryExpression_DT(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    %unaryExpression_DT for unaryOperator :  '&' | '*' | '+' | '-' | '~' | '!'
    
    if strcmp(tree.operator, '~') || strcmp(tree.operator, '!')
        lusDT = 'bool';
        slxDT = 'boolean';
    else
        [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree.rightExp, args);
    end
end

