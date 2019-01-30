function [results, passed, priority] = na_0005(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % na_0005: Port block name visibility in Simulink model
    priority = 2;
    results = {};
    title = 'na_0005: Port block name visibility in Simulink model';
    description_text = ...
        'The name of an Inport or Outportshould not be hidden';
    
    portBlocks = find_system(model,'Regexp', 'on','blocktype','port', ...
        'ShowName','off');
    [results{1}, ~] = ...
        GuidelinesUtils.process_find_system_results(portBlocks,title,...
        description_text,true, true); 
    passed = isempty(portBlocks);

end


