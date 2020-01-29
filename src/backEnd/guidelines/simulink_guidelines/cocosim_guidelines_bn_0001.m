function [results, passed, priority] = cocosim_guidelines_bn_0001(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % ORION GN&C MATLAB/Simulink Standards
    % bn_0001: Subsystem Name Length Limit
    % 32 characters is the maximum limit
    
    priority = 2; % strongly recommended
    results = {};
    passed = 1;
    totalFail = 0;
    
    SubsystemList = find_system(model, 'Regexp', 'on',...
        'blocktype', 'SubSystem');
    SSNames = get_param(SubsystemList, 'Name');
    failedList = {};
    % we check for uniqueness
    title = 'unique name';
    uniqueSubsystemNames = unique(SSNames);
    unique_names = {};
    if length(uniqueSubsystemNames) < length(SSNames)
        uniqueNames = unique(SSNames);
        for i=1:length(uniqueNames)
            failedList = SubsystemList(strcmp(uniqueNames{i},SSNames));
            if length(failedList) > 1
                unique_names{end+1}= GuidelinesUtils.process_find_system_results(failedList, ...
                    uniqueNames{i}, true);
                totalFail = totalFail + 1;
            end
        end
    end
    if ~isempty(unique_names)
        uniqItem = HtmlItem(title, unique_names, 'red', 'red');
    else 
        uniqItem = HtmlItem(title, unique_names, 'green', 'green');
    end
    
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
        {description1, uniqItem, ...
        description2, max_limit_32_chars_in_name}, ...
        color, color);
    
end


