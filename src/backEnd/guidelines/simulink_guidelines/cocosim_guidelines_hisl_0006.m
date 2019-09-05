function [results, passed, priority] = cocosim_guidelines_hisl_0006(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DO-178C/DO-331 Standard Compliance
    % hisl_0006: Usage of While Iterator blocks
    
    priority = 3;
    results = {};
    passed = 1;
    totalFail = 0;
    
    whileList = find_system(model, 'type', 'block', 'blocktype','WhileIterator');
    failedList = {};
    for i=1:numel(whileList)
        maxIters = str2num(get_param(whileList{i}, 'MaxIters'));
        if maxIters == -1
            failedList{end+1} = whileList{i};
        end
    end
    
    title = 'While Iterator blocks with no maximum iteration';
    [noSubsystemInName, numFail] = ...
        GuidelinesUtils.process_find_system_results(whileList,title,...
        true);
    totalFail = totalFail + numFail;
    
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
    
    %the main guideline
    title = 'hisl_0006: Usage of While Iterator blocks';
    description_text = ...
        'Set the While Iterator block parameter ''Maximum number of iterations'' to a positive integer value';
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, noSubsystemInName}, color, color);
end

