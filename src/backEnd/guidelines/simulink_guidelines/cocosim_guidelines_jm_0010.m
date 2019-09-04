function [results, passed, priority] = cocosim_guidelines_jm_0010(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jm_0010: Port block name in Simulink model
    
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;

    item_title = 'Inport must match corresponding signal or bus name';
    failedList = {};
    portBlocks = find_system(model,'Regexp', 'on','blocktype','port');
    for i=1:numel(portBlocks)
        portHandles = get_param(portBlocks{i}, 'PortHandles');
        line = get_param(portHandles.Outport, 'line');
        lineName = get_param(line, 'Name');
        portname = get_param(portBlocks{i}, 'Name');
        if ~MatlabUtils.startsWith(portname, lineName)
            if ~MatlabUtils.endsWith(portname, lineName)
                failedList{end+1} = portBlocks{i};
            end
        end
    end
    [Inport_match_signal, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;

    item_title = 'Outport must match corresponding signal or bus name';
    failedList = {};
    portBlocks = find_system(model,'Regexp', 'on','blocktype','port');
    for i=1:numel(portBlocks)
        portHandles = get_param(portBlocks{i}, 'PortHandles');
        line = get_param(portHandles.Inport, 'line');
        lineName = get_param(line, 'Name');
        portname = get_param(portBlocks{i}, 'Name');
        if ~MatlabUtils.startsWith(portname, lineName)
            if ~MatlabUtils.endsWith(portname, lineName)
                failedList{end+1} = portBlocks{i};
            end
        end
    end
    [Outport_match_signal, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;    
    
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end    
    title = 'jm_0010: Port block name in Simulink model';
    description_text = [...
        'The names of Inport blocks and Outport blocks must match the '...
        'corresponding signal or bus names. <br>'...
        '<b>Exceptions: </b><br>'...
            '&emsp;- When any combination of an Inport block, an Outport '...
            'block, and any other block have the same block name, a '...
            'suffix or prefix should be used on the Inport and Outport '...
            'blocks.<br>'...
            '&emsp;- One common suffix is "_In" for Inportsand "_Out" for '...
            'Outports.<br>'...
            '&emsp;- Any suffix or prefix can be used on the ports, '...
            'however the selected option should be consistent.<br>'...
            '&emsp;- Library blocks and reusable subsystems that '...
            'encapsulate generic functionality.'];
    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, ...
        Inport_match_signal,...
        Outport_match_signal}, ...
        color, color);    

end


