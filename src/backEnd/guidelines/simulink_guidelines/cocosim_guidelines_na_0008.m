function [results, passed, priority] = cocosim_guidelines_na_0008(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %         Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % na_0008: Display of labels on signals
    
        priority = 3;
        results = {};
        passed = 1;
        totalFail = 0;

       allLines = find_system(model,'FindAll', 'On', 'type', 'line');
       % Intialize Line Information Class
       % Parse through lines and Assign the object properties.
       failedInport = {};
       failedFrom = {};
       failedSubsystemSrc = {};
       failedDemux = {};
       failedBusSelector = {};
       failedSelector = {};
       failedGoto = {};
       failedBusCreator = {};
       failedMux = {};
       failedSubsystemDst = {};
       failedOutport = {};

       for i = 1 : length(allLines)
           isLabelDisplayed = ~strcmp(get_param(allLines(i), 'Name'), '');
           if isLabelDisplayed
               continue
           end
           sourceData = get_param(allLines(i),'SrcBlockHandle');
           isSourceBlock = get_param(sourceData, 'Type') == 'block';
           destinationData = get_param(allLines(i),'DstBlockHandle');
           if numel(destinationData) > 1 % ignore line with more than one destination as they are consider as multiple lines with one destination each
               continue
           end
           isDestinationBlock = get_param(destinationData, 'Type') == 'block';
           if isSourceBlock
               blockType = get_param(sourceData, 'blocktype');
               srcPath = strcat(get_param(sourceData, 'Parent'), '/', get_param(sourceData, 'Name'));
               if strcmp(blockType, 'Inport')
                   failedInport{end+1} = srcPath; %#ok<*AGROW>
               elseif strcmp(blockType, 'From')
                   failedFrom{end+1} = srcPath;
               elseif strcmp(blockType, 'SubSystem')
                   failedSubsystemSrc{end+1} = srcPath;
               elseif strcmp(blockType, 'Demux')
                   failedDemux{end+1} = srcPath;
               elseif strcmp(blockType, 'BusSelector')
                   failedBusSelector{end+1} = srcPath;
               elseif strcmp(blockType, 'Selector')
                   failedSelector{end+1} = srcPath;
               end
           end
           if isDestinationBlock
               blockType = get_param(destinationData, 'blocktype');
               dstPath = strcat(get_param(destinationData, 'Parent'), '/', get_param(destinationData, 'Name'));
               if strcmp(blockType, 'Outport')
                   failedOutport{end+1} = dstPath;
               elseif strcmp(blockType, 'Goto')
                   failedGoto{end+1} = dstPath;
               elseif strcmp(blockType, 'BusCreator')
                   failedBusCreator{end+1} = dstPath;
               elseif strcmp(blockType, 'Mux')
                   failedMux{end+1} = dstPath;
               elseif strcmp(blockType, 'SubSystem')
                   failedSubsystemDst{end+1} = dstPath;
               end
           end
       end    
    
    % get linesNames      two type with/without brackets
    % get_param(lineHandle, 'Source')
    % create entered_blocksTypes = {'Inport', 'BusCreator' ...} propagated_blockTypes= {'SubSystem', 'Chart'}

    
    % TODO: signal originating from the following blocks
    item_title = 'Inport block';
    [Inport_signal_display, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedInport,item_title,...
        true, true); 
    totalFail = totalFail + numFail;
    
    item_title = 'From block';
    [From_signal_display, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedFrom,item_title,...
        true, true); 
    totalFail = totalFail + numFail;    

    item_title = 'System block or Stateflow chart block';
    [Subsystem_or_StateflowChartBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedSubsystemSrc,item_title,...
        true, true); 
    totalFail = totalFail + numFail;        

    item_title = 'Bus Selector block';
    [BusSelectorBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedDemux,item_title,...
        true, true); 
    totalFail = totalFail + numFail;      
    
    item_title = 'Demux block';
    [DemuxBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedBusSelector,item_title,...
        true, true); 
    totalFail = totalFail + numFail;      

    item_title = 'Selector block';
    [SelectorBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedSelector,item_title,...
        true, true); 
    totalFail = totalFail + numFail;          
    
    % signal connected to the following destination blocks 
    item_title = 'Outport block';
    [Outport_signal_display, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedOutport,item_title,...
        true, true); 
    totalFail = totalFail + numFail;
    
    item_title = 'Goto block';
    [Goto_signal_display, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedGoto,item_title,...
        true, true); 
    totalFail = totalFail + numFail;    

    item_title = 'Subsystem block';
    [SubsystemBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedSubsystemDst,item_title,...
        true, true); 
    totalFail = totalFail + numFail;        

    item_title = 'Bus Creator block';
    [BusCreatorBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedBusCreator,item_title,...
        true, true); 
    totalFail = totalFail + numFail;      
    
    item_title = 'Mux block';
    [MuxBlock, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedMux,item_title,...
        true, true); 
    totalFail = totalFail + numFail;      

%     item_title = 'Chart block';
%     [ChartBlock, numFail] = ...
%         GuidelinesUtils.process_find_system_results(failedList,item_title,...
%         true, true);
%     totalFail = totalFail + numFail;
%
%
%     item_title = 'Embedded Matlab Block';
%     [EmbeddedMatlabBlock, numFail] = ...
%         GuidelinesUtils.process_find_system_results(failedList,item_title,...
%         true, true);
%     totalFail = totalFail + numFail;
    
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
        'A label must be displayed on any signal connected to the '...
        'following destination blocks (directly or via a basic block '...
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
        MuxBlock}, ...
        color, color);      
end


