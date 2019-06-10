function notSupportedActions = actionToLustreTest()
    %ACTIONTOLUSTRETEST is checking if all the following expressions pass
    %through the parser that is used by the compiler.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    notSupportedActions = {};
    P = fileparts(mfilename('fullpath'));
    mat_file = fullfile(P, 'scripts', 'sfdemosActions.mat');
    if ~exist(mat_file, 'file')
        display_msg(sprintf('File not found: %s', mat_file), ...
            MsgType.ERROR, 'actionToLustreTest', '');
        return;
    end
    M = load(mat_file);
    actions = M.actions;
    conditions = M.conditions;
    
    %add additional Actions here
    additionalActions = {...
        'x++'...
        };
    actions = [actions, additionalActions];
    
    for i = 1 : numel(actions)
        % The following call will raise an exception if something wrong.
        % That's how we will know which test is not passing through.
        
        try
            nasa_toLustre.blocks.Stateflow.utils.getPseudoLusAction(actions{i}, false, true);
        catch
            display_msg(sprintf('Expression Failed: %s', actions{i}), ...
                MsgType.INFO, 'actionToLustreTest', '');
            notSupportedActions{end + 1} = actions{i};
        end
    end
    
    
    for i = 1 : numel(conditions)
        % The following call will raise an exception if something wrong.
        % That's how we will know which test is not passing through.
        try
            nasa_toLustre.blocks.Stateflow.utils.getPseudoLusAction(conditions{i}, true, true);
        catch
            display_msg(sprintf('Condition failed: %s', conditions{i}), ...
                MsgType.INFO, 'actionToLustreTest', '');
            notSupportedActions{end + 1} = conditions{i};
        end
    end
end

