function dt = unaryExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %unaryExpression_DT for unaryOperator :  '&' | '*' | '+' | '-' | '~' | '!'
    
    if strcmp(tree.operator, '~') || strcmp(tree.operator, '!')
        dt = 'bool';
    else
        dt = nasa_toLustre.blocks.Stateflow.utils.MExpToLusDT.expression_DT(tree.rightExp, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    end
end

