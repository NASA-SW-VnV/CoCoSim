function action_Array = split_actions(actions)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~isempty(actions) && iscell(actions)
        actions = actions(~strcmp(actions, ''));
        actions = MatlabUtils.strjoin(actions, '\n');
    end
    % clean actions from comments 
    actions = regexprep(actions, '/\*.+\*/', '');
    delim = '(;|\n)';
    action_Array = regexp(actions, delim, 'split');
    action_Array = cellfun(@(x) regexprep(x, '\s+', ''), ...
        action_Array, 'UniformOutput', false);
    action_Array = action_Array(~strcmp(action_Array,''));
end%split_actions


