function [lusDT, slxDT] = binaryExpression_DT(tree, args)
    %BINARYEXPRESSION_DT for arithmetic operation such as +, *, / ...
    % and relational operation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        
    
    tree_type = tree.type;
    switch tree_type
        case {'relopAND', 'relopelAND',...
                'relopOR', 'relopelOR', ...
                'relopGL', 'relopEQ_NE'}
            lusDT = 'bool';
            slxDT = 'boolean';
        case {'plus_minus', 'mtimes', 'times', ...
                'mrdivide', 'mldivide', 'rdivide', 'ldivide', ...
                'mpower', 'power'}
            [left_lusDT, left_slxDT] = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree.leftExp, args);
            [right_lusDT, right_slxDT] = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree.rightExp, args);
            [lusDT, slxDT] = nasa_toLustre.utils.MExpToLusDT.upperDT(left_lusDT, right_lusDT, left_slxDT, right_slxDT);
        otherwise
            lusDT = '';
            slxDT = '';
    end
end

