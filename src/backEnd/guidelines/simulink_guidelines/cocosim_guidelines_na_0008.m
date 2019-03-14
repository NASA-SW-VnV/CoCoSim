function [results, passed, priority] = cocosim_guidelines_na_0008(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % na_0008: Display of labels on signals
    
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

    
    % TODO: signal originating from the following blocks
    item_title = 'Inport block';
    failedList = {};
    [Inport_signal_display, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;
    
    item_title = 'From block';
    failedList = {};
    [From_signal_display, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;    

    item_title = 'System block or Stateflow chart block';
    failedList = {};
    [Subsystem_or_StateflowChartBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;        

    item_title = 'Bus Selector block';
    failedList = {};
    [BusSelectorBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;      
    
    item_title = 'Demux block';
    failedList = {};
    [DemuxBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;      

    item_title = 'Selector block';
    failedList = {};
    [SelectorBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;          
    
    % signal connected to the following destination blocks 
    item_title = 'Outport block';
    failedList = {};
    [Outport_signal_display, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;
    
    item_title = 'Goto block';
    failedList = {};
    [Goto_signal_display, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;    

    item_title = 'Subsystem block';
    failedList = {};
    [SubsystemBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;        

    item_title = 'Bus Creator block';
    failedList = {};
    [BusCreatorBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;      
    
    item_title = 'Mux block';
    failedList = {};
    [MuxBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;      

    item_title = 'Chart block';
    failedList = {};
    [ChartBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;        
    

    item_title = 'Embedded Matlab Block';
    failedList = {};
    [EmbeddedMatlabBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        true, true); 
    totalFail = totalFail + numFail;       
        
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end    
    
    title = 'na_0008: Display of labels on signals';
    description_text1 = ...
        'A label must be displayed on any signal originating from the following blocks:';
    description1 = HtmlItem(description_text1, {}, 'black', 'black');
    description_text2 = [...
        'A label must be displayed on any signal connected to the <br>'...
        'following destination blocks (directly or via a basic block <br>'...
        'that performs a non transformative operation):'];   
    description2 = HtmlItem(description_text2, {}, 'black', 'black');
    results{end+1} = HtmlItem(title, ...
        {description1, ...
        Inport_signal_display,...
        From_signal_display, ...
        Subsystem_or_StateflowChartBlock,...
        BusSelectorBlock, ...
        DemuxBlock, ...
        SelectorBlock, ...        
        description2, ...
        Outport_signal_display,...
        Goto_signal_display, ...
        SubsystemBlock,...
        BusCreatorBlock, ...
        MuxBlock, ...
        ChartBlock, ...        
        EmbeddedMatlabBlock}, ...
        color, color);      
    

end


