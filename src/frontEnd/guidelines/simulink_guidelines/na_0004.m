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
    
    %object_params = get_param(gcs, 'ObjectParameters');

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
        'Block Display Options: Sample Time Colors set to unchecked';
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
        SampleTimeColorsItem,...
        SortedOrderItem}, ...
        color, color);

end

