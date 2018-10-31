function [results, passed] = jc_0211(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>,
    %         Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0211: Usable characters for Inport block and Outport block
    results = {};
    passed = 1;
    totalFail = 0;

    title = 'should not have blank spaces';
    fsList = find_system(model,'Regexp', 'on','blocktype','port',...
        'Name','\s');
    [no_space_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true, true);
    totalFail = totalFail + numFail;

    title = 'should not start with a number';
    fsList = find_system(model,'Regexp', 'on','blocktype','port',...
        'Name','^\d');
    [leading_number_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true, false);
    totalFail = totalFail + numFail;

    title = 'carriage returns are not allowed';
    fsList = find_system(model,'Regexp', 'on','blocktype','port',...
        'Name','\n');
    [no_carriage_return_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true, false);
    totalFail = totalFail + numFail;

    title = 'cannot have more than one consecutive underscore';
    fsList = find_system(model,'Regexp', 'on','blocktype',...
        'port','Name','__');
    [consecutive_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true, false);
    totalFail = totalFail + numFail;

    title = 'cannot start with an underscore';
    fsList = find_system(model,'Regexp', 'on','blocktype',...
        'port','Name','^_');
    [starts_with_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true, false);
    totalFail = totalFail + numFail;

    title = 'cannot end with an underscore';
    fsList = find_system(model,'Regexp', 'on','Name','_$');
    [ends_with_underscore_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,title,...
        true, false);
    totalFail = totalFail + numFail;

    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end

    title = 'jc_0211: Usable characters for Inport block and Outport block';
    results{end+1} = HtmlItem(title, ...
        {no_space_in_name,leading_number_in_name,...
        no_carriage_return_in_name,consecutive_underscore_in_name,...
        starts_with_underscore_in_name,ends_with_underscore_in_name}, ...
        color, color);

end

