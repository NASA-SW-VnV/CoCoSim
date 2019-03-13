function [results, passed, priority] = bn_0002(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % bn_0002: Signal name length limit
    % 32 characters is the maximum limit
    
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
    
    title = 'maximum limit of 32 characters';
    
    signalList = find_system(model, 'Regexp', 'on','FindAll','on',...
        'type','line');
    
    % get names from handles
    Names = arrayfun(@(x) get_param(x, 'Name'), signalList, 'UniformOutput',...
        false);
    lengths = cellfun(@(x) length(x), Names);
    % remove names less than
    list = signalList(lengths > 32);
    %add parent
    failedList = GuidelinesUtils.ppSignalNames(list);
    [max_limit_32_chars_in_name, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,title,...
        false); 
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end

    title = 'bn_0002: Signal name length limit';
    description_text = ...
        '32 characters is the maximum limit for signal name length';
    description = HtmlItem(description_text, {}, 'black', 'black');    
    results{end+1} = HtmlItem(title, ...
        {description, max_limit_32_chars_in_name}, ...
        color, color);    

end


