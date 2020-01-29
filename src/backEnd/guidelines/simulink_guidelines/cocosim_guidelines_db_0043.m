function [results, passed, priority] = cocosim_guidelines_db_0043(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>,
    %         Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % ORION GN&C MATLAB/Simulink Standards
    % db_0043: Simulink font and font size
    
    priority = 2;
    results = {};
    passed = 1;
    totalFail = 0;

    Objects = find_system(model);    

    % Block names not using same font style
    item_title = 'All block names must have same font style';    
    font_name_list = {};
    % TODO, if include first element:
    % (Debug)[PP] Error using db_0043 (line 28)
    % block_diagram does not have a parameter named 'FontName'    
    for i=2:numel(Objects)
        font_name_list{end+1} = get_param(Objects{i},'FontName');
        font_name_list = unique(font_name_list);
    end
    if numel(font_name_list) > 1
        failedList = {model};
    else
        failedList = {};
    end
    [block_names_font_inconsistent, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        false, false);
    totalFail = totalFail + numFail;
        
    % Block names not using same font size
    item_title = 'All block names must have same font size';    
    font_size_list = [];
    % TODO, if include first element:
    % (Debug)[PP] Error using db_0043 (line 28)
    % block_diagram does not have a parameter named 'FontName'    
    for i=2:numel(Objects)
        font_size_list(end+1) = get_param(Objects{i},'FontSize');
        font_size_list = unique(font_size_list);
    end
    if numel(font_size_list) > 1
        failedList = {model};
    else
        failedList = {};
    end
    [block_names_font_size_inconsistent, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        false, false);
    totalFail = totalFail + numFail;    
    
    % Signal labels not using same font
    item_title = 'All signal labels must have same font style';   
    Objects = find_system(model,'FindAll','on',...
        'type','line'); 
    font_name_list = {};   
    for i=1:numel(Objects)
        font_name_list{end+1} = get_param(Objects(i),'FontName');
        font_name_list = unique(font_name_list);
    end
    if numel(font_name_list) > 1
        failedList = {model};
    else
        failedList = {};
    end
    [signals_font_inconsistent, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        false, false);
    totalFail = totalFail + numFail;    
    
    % Signal labels not using same font size
    item_title = 'All signal labels must have same font size';   
    font_size_list = [];
    for i=1:numel(Objects)
        font_size_list(end+1) = get_param(Objects(i),'FontSize');
        font_size_list = unique(font_size_list);
    end
    if numel(font_size_list) > 1
        failedList = {model};
    else
        failedList = {};
    end
    [signals_font_size_inconsistent, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        false, false);
    totalFail = totalFail + numFail;  
    
    % Block annotations not using same font
    item_title = 'All block annotations  must have same font style';   
    Objects = find_system(model,'FindAll','on',...
        'type','annotation'); 
    font_name_list = {};  
    for i=1:numel(Objects)
        font_name_list{end+1} = get_param(Objects(i),'FontName');
        font_name_list = unique(font_name_list);
    end
    if numel(font_name_list) > 1
        failedList = {model};
    else
        failedList = {};
    end
    [annotations_font_inconsistent, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        false, false);
    totalFail = totalFail + numFail;    
    
    % Block annotations not using same font size
    item_title = 'All block annotations must have same font size';   
    font_size_list = [];
    for i=1:numel(Objects)
        font_size_list(end+1) = get_param(Objects(i),'FontSize');
        font_size_list = unique(font_size_list);
    end
    if numel(font_size_list) > 1
        failedList = {model};
    else
        failedList = {};
    end
    [annotations_font_size_inconsistent, numFail] = ...
        GuidelinesUtils.process_find_system_results(failedList,item_title,...
        false, false);
    totalFail = totalFail + numFail;          
    %%%%
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end

    title = 'db_0043: Simulink font and font size';
    description_text = [...
        'All text elements (block names, block annotations and '...
        'signal labels) except free text annotations within a model '...
        'must have the same font style and font size.  Fonts and '...
        'font size should be selected for legibility. <br>'...
        'The selected font should be directly portable '...
        '(e.g. Simulink/Stateflow default font) or convertible '...
        'between platforms (e.g. Arial/Helvetica 12pt).'];
    description = HtmlItem(description_text, {}, 'black', 'black');      
    results{end+1} = HtmlItem(title, ...
        {description,...
        block_names_font_inconsistent,...
        block_names_font_size_inconsistent,...
        signals_font_inconsistent,...
        signals_font_size_inconsistent,...
        annotations_font_inconsistent, ...
        annotations_font_size_inconsistent, ...
        }, ...
        color, color);

end

