function [results, passed, priority] = cocosim_guidelines_na_0011(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % ORION GN&C MATLAB/Simulink Standards
    % na_0011: Scope of Goto and From blocks

    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
 
    failedList = find_system(model, 'Regexp', 'on', 'type', 'block', ...
        'BlockType', 'Goto', 'TagVisibility', 'global|scope');;
    
    item_title = 'Related Goto and From not on the same level';
    [local_goto, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList, ...
        item_title, true, true);
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
    
    title = 'na_0011: Scope of Goto and From blocks';
    description_text = [...
        'For signal flows the following rules apply:<br>'...
        '&ensp;- From and Goto blocks must use local scope.'];
    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, ...
        local_goto}, ...
        color, color);

end


