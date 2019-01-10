function [results, passed] = hyl_0302(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % hyl_0302: Usable characters for block names

    results = {};
    passed = 1;
    totalFail = 0;
    
    % Find all lines that has non alphabetic caracter, number or underscore
    title = 'Allowed Characters are [a-zA-Z_0-9]';
    fsList1 =  find_system(model,'FindAll','on', 'Regexp', 'on','blocktype','SubSystem',... 
        'Name', '\W');
    fsList2 = find_system(model,'FindAll','on', 'Regexp', 'on','blocktype','SubSystem',... 
        'Name', '^<\w+>$');
    fsList = GuidelinesUtils.ppList(setdiff(fsList1, fsList2));
       
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
    title = 'hyl_0302: Usable characters for block names';
    results{end+1} = HtmlItem(title, ...
        {noSpecialCharacters, ...
        shouldNotStartWithNumber, ...
        list3, list4}, color, color);
end

