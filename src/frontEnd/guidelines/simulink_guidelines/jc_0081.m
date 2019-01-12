function [results, passed, priority] = jc_0081(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0081: Icon display for Port block
    priority = 3;
    title = 'jc_0081: Icon display for Port block';
    results = {};
    % For IconDisplay there are 3 options:
    %      'Signal name' | {'Port number'} | 'Port number and signal name'
    % only 'Port number' number is correct
    portBlocks = find_system(model,'Regexp', 'on','blocktype','port', 'IconDisplay','name');
    passed = isempty(portBlocks);
    [results{1}, ~] = ...
        GuidelinesUtils.process_find_system_results(portBlocks,title,...
        true, true);
end


