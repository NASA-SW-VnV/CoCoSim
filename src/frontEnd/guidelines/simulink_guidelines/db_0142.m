function [results, passed, priority] = db_0142(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % db_0142: Position of block names
    priority = 2;
    title = 'db_0142: Position of block names';
    results = {};
    % For IconDisplay there are 3 options:
    %      'Signal name' | {'Port number'} | 'Port number and signal name'
    % only 'Port number' number is correct
    portBlocks = find_system(model,'Regexp', 'on',...
        'NamePlacement','alternate');
    passed = isempty(portBlocks);
    [results{1}, ~] = ...
        GuidelinesUtils.process_find_system_results(portBlocks,title,...
        true);
end


