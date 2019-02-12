function [results, passed, priority] = na_0004(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>,
    %         Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % na_0004: Simulink model appearance
    priority = 3;
    results = {};
    passed = 1;
    totalFail = 0;
    item_titles = {...
        'View Options: Model Browser set to unchecked', ...
        'View Options: Screen color set to white'...
        };
    param_names = {...
        'ModelBrowserVisibility', ...
        'ScreenColor'...
        };
    param_values = {...
        'on',...%ModelBrowserVisibility
        'white' ...%ScreenColor
        };
    subtitles = cell(length(item_titles)+1, 1);
    for i=1:length(item_titles)
        item_title = item_titles{i};
        param = get_param(gcs, param_names{i});
        if strcmp(param, param_values{i})
            fsList = {model};
        else
            fsList = {};
        end
        [subtitles{i+1}, numFail] = ...
            GuidelinesUtils.process_find_system_results(fsList,item_title,...
            true);
        totalFail = totalFail + numFail;
    end
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end

    title = 'na_0004: Simulink model appearance';
    description_text = [...
        'The model appearance settings should conform to the <br>'...
        'following guidelines when the model is released.  The user <br>',...
        'is free to change the settings during the development process'];
    description = HtmlItem(description_text, {}, 'black', 'black');   
    subtitles{1} = description;
    results{end+1} = HtmlItem(title, subtitles, color, color);
end
function [results, passed, priority] = na_0004V2(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>,
    %         Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ORION GN&C MATLAB/Simulink Standards
    % na_0004: Simulink model appearance
    priority = 3;
    results = {};
    passed = 1;
    totalFail = 0;

    % View Options
    item_title = 'View Options: Model Browser set to unchecked';
    modelBrowserVis = get_param(gcs, 'ModelBrowserVisibility');
    if strcmp(modelBrowserVis,'on')
        fsList = {model};
    else
        fsList = {};
    end
    [modelBrowserVisibility, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;    
    
    item_title = 'View Options: Screen color set to white';
    backgroundColor = get_param(model, 'ScreenColor');
    if strcmp(backgroundColor,'white')
        fsList = {};
    else
        fsList = {model};
    end
    [backgroundColorItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;      
    
    item_title = 'View Options: Status bar set to checked';
    statusBar = get_param(model, 'StatusBar');
    if strcmp(statusBar,'on')
        fsList = {};
    else
        fsList = {model};
    end
    [statusBarItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;   
    
    item_title = 'View Options: Tool bar set to on';
    toolBar = get_param(model, 'ToolBar');
    if strcmp(toolBar,'on')
        fsList = {};
    else
        fsList = {model};
    end
    [toolBarItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;       
    
    item_title = 'View Options: Zoom factor set to normal (100%)';
    ZoomFactor = get_param(model, 'ZoomFactor');
    if strcmp(ZoomFactor,'100')
        fsList = {};
    else
        fsList = {model};
    end
    [ZoomFactorItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;       
    
    % Block Display Options
    
%     
%     item_title = ...
%         'Block Display Options: Background Color set to white';
%     BackgroundColor = get_param(model, 'BackgroundColor');
%     if strcmp(BackgroundColor,'off')
%         fsList = {};
%     else
%         fsList = {model};
%     end
%     [BackgroundColor, numFail] = ...
%         GuidelinesUtils.process_find_system_results(fsList,item_title,...
%         true);
%     totalFail = totalFail + numFail;       
%     
%     
%     item_title = ...
%         'Block Display Options: Background Color set to white';
%     ForegroundColor = get_param(model, 'ForegroundColor');
%     if strcmp(ForegroundColor,'off')
%         fsList = {};
%     else
%         fsList = {model};
%     end
%     [ForegroundColor, numFail] = ...
%         GuidelinesUtils.process_find_system_results(fsList,item_title,...
%         true);
%     totalFail = totalFail + numFail;        
    
    item_title = ...
        'Block Display Options: Execution Context Indicator set to unchecked';
    ExecutionContextIndicator = get_param(model, 'ExecutionContextIcon');
    if strcmp(ExecutionContextIndicator,'off')
        fsList = {};
    else
        fsList = {model};
    end
    [ExecutionContextIndicatorItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;      
      
    item_title = ...
        'Block Display Options: Library Link Display set to none';
    LibraryLinkDisplay = get_param(model, 'LibraryLinkDisplay');
    if strcmp(LibraryLinkDisplay,'none')
        fsList = {};
    else
        fsList = {model};
    end
    [LibraryLinkDisplayItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;      
      
    item_title = ...
        'Block Display Options: Show Linearization Annotations set to checked';
    ShowLinearizationAnnotations = get_param(model, 'ShowLinearizationAnnotations');
    if strcmp(ShowLinearizationAnnotations,'on')
        fsList = {};
    else
        fsList = {model};
    end
    [ShowLinearizationAnnotationsItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail; 
      
    item_title = ...
        'Block Display Options: Show Model Reference Block IO set to unchecked';
    ShowModelReferenceBlockIO = get_param(model, 'ShowModelReferenceBlockIO');
    if strcmp(ShowModelReferenceBlockIO,'off')
        fsList = {};
    else
        fsList = {model};
    end
    [ShowModelReferenceBlockIOItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail; 

    item_title = ...
        'Block Display Options: Show Model Reference Block Version set to unchecked';
    ShowModelReferenceBlockVersion = get_param(model, 'ShowModelReferenceBlockIO');
    if strcmp(ShowModelReferenceBlockVersion,'off')
        fsList = {};
    else
        fsList = {model};
    end
    [ShowModelReferenceBlockVersionItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail; 
        
    item_title = ...
        'Block Display Options: Sample Time Colors set to off';
    SampleTimeColors = get_param(model, 'SampleTimeColors');
    if strcmp(SampleTimeColors,'off')
        fsList = {};
    else
        fsList = {model};
    end
    [SampleTimeColorsItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;         
    
    item_title = ...
        'Block Display Options: Sorted Order set to unchecked';
    SortedOrder = get_param(model, 'SortedOrder');
    if strcmp(SortedOrder,'off')
        fsList = {};
    else
        fsList = {model};
    end
    [SortedOrderItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;     
    
    % Signal Display Options
    
    item_title = ...
        'Signal Display Options: Show Port Data Types set to unchecked';
    ShowPortDataTypes = get_param(model, 'ShowPortDataTypes');
    if strcmp(ShowPortDataTypes,'off')
        fsList = {};
    else
        fsList = {model};
    end
    [ShowPortDataTypesItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;       
    
    item_title = ...
        'Signal Display Options: Show Line Dimensions set to unchecked';
    ShowLineDimensions = get_param(model, 'ShowLineDimensions');
    if strcmp(ShowLineDimensions,'off')
        fsList = {};
    else
        fsList = {model};
    end
    [ShowLineDimensionsItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;     
        
    item_title = ...
        'Signal Display Options: Show Storage Class set to unchecked';
    ShowStorageClass = get_param(model, 'ShowLineDimensions');
    if strcmp(ShowStorageClass,'off')
        fsList = {};
    else
        fsList = {model};
    end
    [ShowStorageClassItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;        
    
    item_title = ...
        'Signal Display Options: Show Test Point Icons set to checked';
    ShowTestPointIcons = get_param(model, 'ShowTestPointIcons');
    if strcmp(ShowTestPointIcons,'on')
        fsList = {};
    else
        fsList = {model};
    end
    [ShowTestPointIconsItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;     
        
    item_title = ...
        'Signal Display Options: Show Viewer Icons set to checked';
    ShowViewerIcons = get_param(model, 'ShowViewerIcons');
    if strcmp(ShowViewerIcons,'on')
        fsList = {};
    else
        fsList = {model};
    end
    [ShowViewerIconsItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;         

    item_title = ...
        'Signal Display Options: Wide Non-scalar Lines set to checked';
    WideLines = get_param(model, 'WideLines');
    if strcmp(WideLines,'on')
        fsList = {};
    else
        fsList = {model};
    end
    [WideLinesItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;       
    
    % Simulation
    
    item_title = ...
        'Simulation: Simulation Mode set normal';
    SimulationMode = get_param(model, 'SimulationMode');
    if strcmp(SimulationMode,'normal')
        fsList = {};
    else
        fsList = {model};
    end
    [SimulationModeItem, numFail] = ...
        GuidelinesUtils.process_find_system_results(fsList,item_title,...
        true);
    totalFail = totalFail + numFail;     
        
    %%%%
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end

    title = 'na_0004: Simulink model appearance';
    description_text = [...
        'The model appearance settings should conform to the <br>'...
        'following guidelines when the model is released.  The user <br>',...
        'is free to change the settings during the development process'];
    description = HtmlItem(description_text, {}, 'black', 'black');      
    results{end+1} = HtmlItem(title, ...
        {description,...
        modelBrowserVisibility,...
        backgroundColorItem,...
        statusBarItem,...
        toolBarItem,...
        ZoomFactorItem,...
        ExecutionContextIndicatorItem,...
        LibraryLinkDisplayItem,...
        ShowLinearizationAnnotationsItem,...
        ShowModelReferenceBlockIOItem,...
        ShowModelReferenceBlockVersionItem,...
        SampleTimeColorsItem,...
        SortedOrderItem,...
        ShowPortDataTypesItem,...
        ShowLineDimensionsItem,...
        ShowStorageClassItem,...
        ShowTestPointIconsItem,...
        ShowViewerIconsItem,...
        WideLinesItem,...
        SimulationModeItem}, ...
        color, color);

end

