function [results, passed, priority] = hyl_0307(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % hyl_0307: No "subsystem" in block name
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
    
    % Should not start with a number
    title = 'No "subsystem" in block name';
    fsList = find_system(model, 'Regexp', 'on','CaseSensitive','off',...
        'blocktype','SubSystem', 'Name', 'subsystem');
    [noSubsystemInName, numFail] = ...
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
    title = 'hyl_0307:  Use of subsystem name';
    description_text = ...
        'No block shall have "subsystem" in the name';
    description = HtmlItem(description_text, {}, 'black', 'black');    
    results{end+1} = HtmlItem(title, ...
        {description, noSubsystemInName}, color, color);
end

