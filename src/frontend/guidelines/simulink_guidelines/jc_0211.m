function [results, passed, priority] = jc_0211(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>,
    %         Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0211: Usable characters for Inport block and Outport block
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
    
    % Should not start with a number    
    title = 'should not start with a number';
    fsList = find_system(model,'Regexp', 'on','blocktype','port',...
        'Name','^\d');
    [leading_number_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;    

    title = 'should not have blank spaces';
    fsList = find_system(model,'Regexp', 'on','blocktype','port',...
        'Name','\s');
    [no_space_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;

    title = 'carriage returns are not allowed';
    fsList = find_system(model,'Regexp', 'on','blocktype','port',...
        'Name','\n');
    [no_carriage_return_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;
    
    title = 'Allowed Characters are [a-zA-Z_0-9]';
    failedList = GuidelinesUtils.allowedChars(model,{'FindAll','on','blocktype','port'});
    % fsList = GuidelinesUtils.ppSignalNames(failedList);    
    [noSpecialCharacters, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true, false);
    totalFail = totalFail + numFail;    

    % cannot have more than one consecutive underscore
    title = 'cannot have more than one consecutive underscore';
    fsList = find_system(model,'Regexp', 'on','blocktype',...
        'port','Name','__');
    [consecutive_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;

    % cannot start with an underscore
    title = 'cannot start with an underscore';
    fsList = find_system(model,'Regexp', 'on','blocktype',...
        'port','Name','^_');
    [starts_with_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true);
    totalFail = totalFail + numFail;

    % cannot end with an underscore
    title = 'cannot end with an underscore';
    fsList = find_system(model,'Regexp', 'on','Name','_$');
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

    title = 'jc_0211: Usable characters for Inport block and Outport block';
    description_text = ...
        'The names of all Inport blocks and Outport blocks should conform to the following constraints:';
    description = HtmlItem(description_text, {}, 'black', 'black');      
    results{end+1} = HtmlItem(title, ...
        {description,...
        leading_number_in_name,no_space_in_name,...
        no_carriage_return_in_name,noSpecialCharacters,...
        consecutive_underscore_in_name,...
        starts_with_underscore_in_name,ends_with_underscore_in_name}, ...
        color, color);

end

