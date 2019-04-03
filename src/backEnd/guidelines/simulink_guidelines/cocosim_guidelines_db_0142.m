function [results, passed, priority] = cocosim_guidelines_db_0142(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % db_0142: Position of block names
    
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;
    
    % For IconDisplay there are 3 options:
    %      'Signal name' | {'Port number'} | 'Port number and signal name'
    % only 'Port number' number is correct
    item_title = 'NamePlacement should not be set to "alternate"';
    failedBlocks = find_system(model,'Regexp', 'on',...
        'NamePlacement','alternate');
    [namePlacement_alternate, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedBlocks,item_title,...
        true);
    
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end      
  
    title = 'db_0142: Position of block names';
    description_text = ...
        'If shown,the name of each block should be placed below the block';    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, namePlacement_alternate}, ...
        color, color);     
    
end


