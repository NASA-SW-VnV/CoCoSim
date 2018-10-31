function [results, passed] = na_0005(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % na_0005: Port block name visibility in Simulink model

    results = {};
    title = 'na_0005: Port block name visibility in Simulink model';
    portBlocks = find_system(model,'Regexp', 'on','blocktype','port', ...
        'ShowName','off');
    [results{1}, ~] = ...
        GuidelinesUtils.process_find_system_results(portBlocks,title,...
        true, true); 
    passed = isempty(portBlocks);

end


