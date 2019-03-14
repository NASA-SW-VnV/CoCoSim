function [results, passed, priority] = cocosim_guidelines_jc_0081(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0081: Icon display for Port block
    
    priority = 3;  
    results = {};
    passed = 1;
    totalFail = 0;    
    
    % For IconDisplay there are 3 options:
    %      'Signal name' | {'Port number'} | 'Port number and signal name'
    % only 'Port number' number is correct
    item_title = 'Only "Port number" setting is correct for IconDisplay';
    portBlocks = find_system(model,'Regexp', 'on','blocktype','port', 'IconDisplay','name');
    [only_Port_number_is_correct, numFail] = ...
        GuidelinesUtils.process_find_system_results(portBlocks,item_title,...
        true, true);
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end      
  
    title = 'jc_0081: Icon display for Port block';
    description_text = ...
        'The "Icon display" setting should be set to "Port number" for Inport and Outport blocks';    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, only_Port_number_is_correct}, ...
        color, color);      
    
end


