function [results, passed, priority] = hyl_0305(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % hyl_0305: Block names shall not be made unique by using case.
    
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
    
    % Should not start with a number
    title = 'Block names shall not be made unique by using case.';
    blockList = find_system(model);
    % get names from handles
    Names = get_param(blockList, 'Name');
    description_text = ...
        'Block names shall not be made unique by using case';
    description = HtmlItem(description_text, {}, 'black', 'black');      
    
    uniqueUsingCase = {description};
    for i=1:numel(Names)
        if isempty(Names{i})
            continue;
        end
        I = strcmpi(Names{i},Names);
        if sum(double(I)) > 1
            uniqueUsingCase{end+1} = GuidelinesUtils.process_find_system_results(...
                blockList(I),Names{i}, true, false);
            totalFail = totalFail + 1; 
            Names(I) = {''};
        end
    end

    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
        
    %the main guideline
    title = 'hyl_0305: Block name uniqueness';   
    results{end+1} = HtmlItem(title, ...
        uniqueUsingCase, color, color);
end

