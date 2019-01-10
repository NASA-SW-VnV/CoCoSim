function [results, passed] = jc_0221(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0221: Usable characters for signal line names

    results = {};
    passed = 1;
    totalFail = 0;
    
    % Find all lines that has non alphabetic caracter, number or underscore
    title = 'Allowed Characters are [a-zA-Z_0-9]';
%     fsList1 =  find_system(model, 'Regexp', 'on','FindAll','on',...
%         'type','line', 'Name', '\W');
%     fsList2 = find_system(model, 'Regexp', 'on','FindAll','on',...
%         'type','line', 'Name', '^<\w+>$');
    failedList = GuidelinesUtils.allowedChars(model,{'type','line'});
    fsList = GuidelinesUtils.ppList(failedList);
       
    [noSpecialCharacters, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title, ...
        false, false);
    totalFail = totalFail + numFail;
    
    % Should not start with a number
    fsList = GuidelinesUtils.ppList(...
        find_system(model, 'Regexp', 'on','FindAll','on',...
        'type','line', 'Name', '^[\d_]'));
    title = 'Should not start with a number or underscore';
    [shouldNotStartWithNumber, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        false, false);
    totalFail = totalFail + numFail;
    
    % cannot have more than one consecutive underscore
    fsList = GuidelinesUtils.ppList(...
        find_system(model, 'Regexp', 'on','FindAll','on',...
        'type','line', 'Name', '__'));
    title = 'cannot have more than one consecutive underscore';
    [list3, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        false, false);
    totalFail = totalFail + numFail;
    
    % cannot end with an underscore
    fsList = GuidelinesUtils.ppList(...
        find_system(model, 'Regexp', 'on','FindAll','on',...
        'type','line', 'Name', '_$'));
    title = 'cannot end with an underscore';
    [list4, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        false, false);
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
        {noSpecialCharacters, ...
        shouldNotStartWithNumber, ...
        list3, list4}, color, color);
end


