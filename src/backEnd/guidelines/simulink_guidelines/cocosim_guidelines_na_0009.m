function [results, passed, priority] = cocosim_guidelines_na_0009(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % na_0009: Entry versus propagation of signal labels

    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;

    allLines = find_system(model,'FindAll', 'On', 'type', 'line');
    % Intialize Line Information Class
    %allLineProperties = LineInformation;
    % Parse through lines and Assign the object properties.
    for i = 1 : length(allLines)
        %allLineProperties(i).Identifier =  allLines(i);
        sourceData = get_param(allLines(i),'SrcBlockHandle');
        destinationData = get_param(allLines(i),'DstBlockHandle');
        sourcePortData = get_param(allLines(i),'SrcportHandle');
        destinationPortData = get_param(allLines(i),'DstportHandle');
        SourceBlock =  get_param(sourceData, 'Name');
        DestinationBlock =  get_param(destinationData, 'Name');
        SourcePort =  get_param(sourcePortData, 'Name');
        DestinationPort =  get_param(destinationPortData, 'Name');
    end

    %         lineList = find_system(model, 'Regexp', 'on','FindAll','on',...
    %             'type','line');
    %     for i=1:numel(lineList)
    %         lineName = get_param(lineList(i),'Name');
    %         source = get_param(lineList(i), 'SourceBlock');
    %         % if < , then propagate
    %         display(lineName);
    %         display(source);
    %     end    
    % get linesNames      two type with/without brackets
    % get_param(lineHandle, 'Source')
    % create entered_blocksTypes = {'Inport', 'BusCreator' ...} propagated_blockTypes= {'SubSystem', 'Chart'}

    item_title = 'Inport block';
    failedList = {};
    [Inport_signal_display, numFail] = ...
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
    
    title = 'na_0009: Entry versus propagation of signal labels';
    description_text = [...
        'If a label is present on a signal, the following rules define '...
        'whether that label shall be created there (entered directly '...
        'on the signal) or propagated from its true source '...
        '(inherited from elsewhere in the model by using the "<" character). <br>'...
        '&ensp;1. Any displayed signal label must be entered for signals that: <br>'...
        '&emsp;a. Originate from an Inport at the Root (top) Level of a model <br>'...
        '&emsp;b. Originate from a basic block that performs a transformative operation '...
        '         (For the purpose of interpreting this rule only, the Bus Creator block, '...
        '         Mux block and Selector block shall be considered to be included among '...
        '         the blocks that perform transformative operations.) <br>'...
        '&ensp;2. Any displayed signal label must be propagated for signals that: <br>'...
        '&emsp;a. Originate from an Inport block in a nested subsystem<br>'...
        '        <b>Exception:</b> If the nested subsystem is a library subsystem, a label may '...
        '        be entered on the signal coming from the Inport to accommodate reuse '...
        '        of the library block. <br>'...
        '&emsp;b. Originate from a basic block that performs a '...
        '        non-transformative operation <br>'...
        '&emsp;c. Originate from a Subsystem or Stateflow chart block <br>'...
        '        <b>Exception:</b> If the connection originates from the output of a library '...
        '        subsystem block instance, a new label may be entered on the signal to '...
        '        accommodate reuse of the library block.'];    
    
    
    description = HtmlItem(description_text, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description, ...
        Outport_match_signal}, ...
        color, color);   

end


