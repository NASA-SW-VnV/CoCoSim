function [results, passed, priority] = jc_0221(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0221: Usable characters for signal line names
    % h_0040: Usable characters for Simulink Bus Names
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
    
    % Should not start with a number
    fsList = GuidelinesUtils.ppSignalNames(find_system(model, 'Regexp', 'on', 'FindAll','on',...
        'type','line', 'Name', '^[\d]'));
    title = 'Should not start with a number or underscore';
    [shouldNotStartWithNumber, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        false);
    totalFail = totalFail + numFail;
    
    % Should not have blank spaces
    title = 'should not have blank spaces';
    fsList = GuidelinesUtils.ppSignalNames(find_system(model,'Regexp', 'on','FindAll','on',...
        'type','line', 'Name','\s'));
    [no_space_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        false);
    totalFail = totalFail + numFail;    
    
    % carriage returns are not allowed
    title = 'carriage returns are not allowed';
    fsList = GuidelinesUtils.ppSignalNames(find_system(model,'Regexp', 'on','FindAll','on',...
        'type','line', 'Name','\n'));
    [no_carriage_return_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        false);
    totalFail = totalFail + numFail;    
        
    % Find all lines that has non alphabetic character, number or underscore
    title = 'Allowed Characters are [a-zA-Z_0-9]';
    failedList = GuidelinesUtils.allowedChars(model,{'FindAll','on','type','line'});
    fsList = GuidelinesUtils.ppSignalNames(failedList);       
    [noSpecialCharacters, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title, ...
        false);
    totalFail = totalFail + numFail;    
    
    % cannot have more than one consecutive underscore
    fsList = GuidelinesUtils.ppSignalNames(find_system(model, 'Regexp', 'on','FindAll','on',...
        'type','line', 'Name', '__'));
    title = 'cannot have more than one consecutive underscore';
    [consecutive_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        false);
    totalFail = totalFail + numFail;
    
    % cannot start with an underscore
    title = 'cannot start with an underscore';
    fsList = GuidelinesUtils.ppSignalNames(find_system(model,'Regexp', 'on', 'FindAll','on',...
        'type','line', 'Name','^_'));
    [starts_with_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        false);
    totalFail = totalFail + numFail;    
    
    % cannot end with an underscore
    fsList = GuidelinesUtils.ppSignalNames(find_system(model, 'Regexp', 'on','FindAll','on',...
        'type','line', 'Name', '_$'));
    title = 'cannot end with an underscore';
    [ends_with_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        false);
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
        
    %the main guideline
    title = 'jc_0221: Usable characters for signal line names';
    results{end+1} = HtmlItem(title, ...
        {
        shouldNotStartWithNumber, ...
        no_space_in_name, ...
        no_carriage_return_in_name, ...
        noSpecialCharacters, ...
        consecutive_underscore_in_name, ...
        starts_with_underscore_in_name, ...
        ends_with_underscore_in_name}, color, color);
end


