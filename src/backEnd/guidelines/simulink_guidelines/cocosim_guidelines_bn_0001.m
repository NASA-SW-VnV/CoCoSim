function [results, passed, priority] = cocosim_guidelines_bn_0001(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % bn_0001: Subsystem Name Length Limit
    % 32 characters is the maximum limit
    
    priority = 2; % strongly recommended
    results = {};
    passed = 1;
    totalFail = 0;
    
    SubsystemList = find_system(model, 'Regexp', 'on',...
        'blocktype', 'SubSystem');
    failedList = {};
    % we check for uniqueness
    title = 'unique name';
    uniqueSubsystemList = unique(SubsystemList);
    if length(uniqueSubsystemList) < length(SubsystemList)
        [C,ia,ib] = unique(SubsystemList,'rows','stable');
        failedList = SubsystemList(hist(ib,unique(ib))>1);
    end
    [unique_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList, ...
        title, true);
    totalFail = totalFail + numFail;
    
    % we check for name length limit
    title = 'maximum limit of 32 characters';
    Names = get_param(SubsystemList, 'Name');
    lengths = cellfun(@(x) length(x), Names);
    % remove names less than
    failedList = SubsystemList(lengths > 32);
    %add parent
    %failedList = GuidelinesUtils.ppSussystemNames(list);
    [max_limit_32_chars_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList, title, ...
        true);
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
    
    % the main guideline
    title = 'bn_0001: Subsystem name length limit'; 
    description_text1 = ...
        'The names of all Subsystem blocks must be unique';
    description1 = HtmlItem(description_text1, {}, 'black', 'black');
    description_text2 = ...
        '32 characters is the maximum limit for subsystem name length';
    description2 = HtmlItem(description_text2, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description1, unique_name, ...
        description2, max_limit_32_chars_in_name}, ...
        color, color);
    
end


