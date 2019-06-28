function [results, passed, priority] = cocosim_guidelines_jc_0141(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0141: Use of the Switch block
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
 
    failedList = find_system(model, 'Regexp', 'on', 'type', 'block', ...
        'BlockType', 'Switch', 'Criteria', '.*>.*');
    
    item_title = 'Wrong switch parameter';
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
    
    title = 'jc_0141: Use of the Switch blocks';
    description_text = [...
        'The block parameter ?Criteria for passing first input? should '...
        'be set to u2~=0. The block parameter ?Criteria for passing '...
        'first input? must not be set to u2>Threshold for R13 versions '...
        'of MATLAB.<br>'...
        'The logic for the switch block should be defined on the '...
        'same level as the switch block itself.'];
    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, ...
        local_goto}, ...
        color, color);

end


