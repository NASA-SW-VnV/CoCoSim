function dt = binaryExpression_DT(tree, data_map, inputs, isSimulink, ...
    isStateFlow, isMatlabFun)
    %BINARYEXPRESSION_DT for arithmetic operation such as +, *, / ...
    % and relational operation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT
    tree_type = tree.type;
    switch tree_type
        case {'relopAND', 'relopelAND',...
                'relopOR', 'relopelOR', ...
                'relopGL', 'relopEQ_NE'}
            dt = 'bool';
        case {'plus_minus', 'mtimes', 'times', ...
                'mrdivide', 'mldivide', 'rdivide', 'ldivide', ...
                'mpower', 'power'}
            left_dt = MExpToLusDT.expression_DT(tree.leftExp, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
            right_dt = MExpToLusDT.expression_DT(tree.rightExp, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
            dt = MExpToLusDT.upperDT(left_dt, right_dt);
        otherwise
            dt = '';
    end
end

