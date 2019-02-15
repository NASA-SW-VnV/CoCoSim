function [results, passed, priority] = bn_0001(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % bn_0001: Sussystem name length limit
    % 32 characters is the maximum limit
    
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
    
    title = 'maximum limit of 32 characters';
    
    SussystemList = find_system(model, 'Regexp', 'on',...
        'blocktype','SubSystem');
    
%     % TODO:  do we need to check for uniqueness
%     uniqueSussystemList = unique(SussystemList);
%     if length(uniqueSussystemList) < length(uniqueSussystemList)
%         
%     end

    lengths = cellfun(@(x) length(x), SussystemList);
    % remove names less than
    failedList = SussystemList(lengths > 32);
    %add parent
    %failedList = GuidelinesUtils.ppSussystemNames(list);
    [max_limit_32_chars_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        true);
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
    
    title = 'bn_0001: Sussystem name length limit';    
    description_text = ...
        '32 characters is the maximum limit for subsystem name length';
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, max_limit_32_chars_in_name}, ...
        color, color);
    
end


