function actionToLustreTest()
    %ACTIONTOLUSTRETEST is checking if all the following expressions pass
    %through the parser that is used by the compiler.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    actions = {...
        'out = 0', ...
        'x++', ...
        'out = abs(x)'};
    
    for i = 1 : numel(actions)
        % The following call will raise an exception if something wrong.
        % That's how we will know which test is not passing through.
        display_msg(sprintf('Original Expression: %s', actions{i}), ...
            MsgType.INFO, 'actionToLustreTest', '');
        lus_action = SF_To_LustreNode.getPseudoLusAction(actions{i}, false, true);
        display_msg(sprintf('Lustre Expression: %s', lus_action.print('LUSTREC')), ...
            MsgType.RESULT, 'actionToLustreTest', '');
    end
    
    conditions = {...
        'x == 1 || f(y) > x', ...
        'f(y, x) > x'};
    
    for i = 1 : numel(conditions)
        % The following call will raise an exception if something wrong.
        % That's how we will know which test is not passing through.
        display_msg(sprintf('Original Expression: %s', conditions{i}), ...
            MsgType.INFO, 'actionToLustreTest', '');
        lus_action = SF_To_LustreNode.getPseudoLusAction(conditions{i}, true, true);
        display_msg(sprintf('Lustre Expression: %s', lus_action.print('LUSTREC')), ...
            MsgType.RESULT, 'actionToLustreTest', '');
    end
end

