function [results, passed, priority] = cocosim_guidelines_na_0005(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % na_0005: Port block name visibility in Simulink model
    
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;

    item_title = '"Format / Hide Name" is not allowed';
    portBlocks = find_system(model,'Regexp', 'on','blocktype','port', ...
        'ShowName','off');
    [hide_name_not_allowed, numFail] = ...
        GuidelinesUtils.process_find_system_results(portBlocks,item_title,...
        true, true); 
    totalFail = totalFail + numFail;
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end    
    title = 'na_0005: Port block name visibility in Simulink model';
    description_text = ...
        'The name of an Inport or Outport should not be hidden';    
    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, hide_name_not_allowed}, ...
        color, color);    

end


