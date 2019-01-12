function [results, passed, priority] = jc_0201(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0201: Usable characters in subsystem names
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
    
    % Should not start with a number
    title = 'should not start with a number';
    fsList = find_system(model, 'Regexp', 'on',...
        'blocktype','SubSystem', 'Name', '^[\d_]');
    [shouldNotStartWithNumber, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;
    
    % Should not have blank spaces
    title = 'should not have blank spaces';    
    fsList = find_system(model, 'Regexp', 'on',...
        'blocktype','SubSystem', 'Name', '\s');    
    [no_space_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;     
    
    % carriage returns are not allowed
    title = 'carriage returns are not allowed';  
    fsList = find_system(model, 'Regexp', 'on',...
        'blocktype','SubSystem', 'Name', '\n');  
    [no_carriage_return_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;    
    
    % Find all lines that has non alphabetic caracter, number or underscore
    title = 'Allowed Characters are [a-zA-Z_0-9]';
    failedList = GuidelinesUtils.allowedChars(model,{});      
    [noSpecialCharacters, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title, ...
        true);
    totalFail = totalFail + numFail;           
    
    % cannot have more than one consecutive underscore
    title = 'cannot have more than one consecutive underscore';    
    fsList = find_system(model, 'Regexp', 'on',...
        'blocktype','SubSystem', 'Name', '__');
    [consecutive_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;
    
    % cannot start with an underscore
    title = 'cannot start with an underscore';
    fsList = find_system(model,'Regexp', 'on',...
        'blocktype','SubSystem', 'Name','^_');
    [starts_with_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;    
    
    % cannot end with an underscore
    title = 'cannot end with an underscore';
    fsList = find_system(model,'Regexp', 'on',...
        'blocktype','SubSystem', 'Name','_$');
    [ends_with_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
        
    %the main guideline
    title = 'jc_0201: Usable characters in subsystem names';
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

