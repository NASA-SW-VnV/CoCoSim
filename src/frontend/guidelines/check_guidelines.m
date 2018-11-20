function [report_path, status] = check_guidelines(model_path, varargin)
    % check_guidelines checks guidelines defined in guidelines_order script
    % This is a generic function that use guidelines_config as a configuration
    % file that decides which libraries to use and in which order to call the
    % checks functions.
    % See guidelines_config for more details.
    % Inputs:
    % model_path: The full path to Simulink model.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    status = 0;
    
    mode_display = 1;
    for i=1:numel(varargin)
        if strcmp(varargin{i}, 'nodisplay')
            mode_display = 0;
            break;
        end
    end
    
    %% load the model
    [model_parent, model_base, ~] = fileparts(model_path);
    load_system(model_path);
    output_dir = fullfile(model_parent, 'cocosim_output', model_base);
    report_path = fullfile(output_dir, strcat(model_base, '_GUIDELINES.html'));
    if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end
    
    
    %% Order functions
    global ordered_guidelines_functions;
    if isempty(ordered_guidelines_functions)
        guidelines_config;
    end
    %% sort functions calls
    oldDir = pwd;
    warning off
    items_list = {};
    for i=1:numel(ordered_guidelines_functions)
        [dirname, func_name, ~] = fileparts(ordered_guidelines_functions{i});
        cd(dirname);
        fh = str2func(func_name);
        try
            display_msg(['runing ' func2str(fh)], MsgType.INFO, 'PP', '');
            [items_list_i, passed] = fh(model_base);
            if passed
                %add it to the end of the list
                items_list = [items_list, items_list_i];
            else
                items_list = [items_list_i, items_list];
            end
        catch me
            display_msg(['can not run ' func2str(fh)], MsgType.WARNING, 'PP', '');
            display_msg(me.getReport(), MsgType.DEBUG, 'PP', '');
            status = 1;
        end
        
    end
    title = 'NASA Orion GN&C MATLAB/Simulink Standards';
    report_path = MenuUtils.createHtmlListUsingHTMLITEM(title, items_list, report_path, model_base);
    % warning on
    cd(oldDir);
    if mode_display
        open(report_path);
    end
    display_msg(['Report path: ' report_path], MsgType.RESULT, 'PP', '');
    display_msg('Done with the guidelines checking.', MsgType.INFO, 'PP', '');
end