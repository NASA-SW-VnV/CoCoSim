function [results, passed, priority] = cocosim_guidelines_jc_0281(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % jc_0281: Naming of Trigger Port block and Enable Port block

    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;

    blockList = find_system(model, 'type', 'block', 'BlockType', ...
        'SubSystem');
    failedTrigger = {};
    failedEnable = {};
    for i = 1:numel(blockList)
        ports = get_param(blockList{i}, 'PortHandles');
        if ~isempty(ports.Trigger)
            trigger = find_system(model, 'type', 'block', ...
                'BlockType', 'TriggerPort', 'Parent', blockList{i});
            triggerName = get_param(trigger, 'Name');
            blockHandle = get_param(blockList{i}, 'Handle');
            line = find_system(model, 'FindAll', 'On', 'type', ...
                'line', 'Name', triggerName{1}, ...
                'DstBlockHandle', blockHandle);
            if isempty(line)
                failedTrigger{end+1} = blockList{i}; %#ok<AGROW>
            end
        end
        
        if ~isempty(ports.Enable)
            enable = find_system(model, 'type', 'block', ...
                'BlockType', 'EnablePort', 'Parent', blockList{i});
            enableName = get_param(enable, 'Name');
            blockHandle = get_param(blockList{i}, 'Handle');
            line = find_system(model, 'FindAll', 'On', ...
                'type', 'line', 'Name', enableName{1}, ...
                'DstBlockHandle', blockHandle);
            if isempty(line)
                failedEnable{end+1} = blockList{i}; %#ok<AGROW>
            end
        end   
    end
    item_title = 'Same name for trigger block and signal';
    [different_trigger_names, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedTrigger, ...
        item_title, true, true);
    totalFail = totalFail + numFail;
    
    item_title = 'Same name for enable block and signal';
    [different_enable_names, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedEnable, ...
        item_title, true, true); 
    totalFail = totalFail + numFail; 
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end        
    
    title = 'jc_0281: Naming of Trigger Port block and Enable Port block';
    description_text = [...
        'For Trigger port blocks and Enable port blocks<br>'...
        '&ensp;- The block name should match the name of the signal '...
        'triggering the subsystem <br>'];    
    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, ...
        different_trigger_names, ...
        different_enable_names}, ...
        color, color);   

end


