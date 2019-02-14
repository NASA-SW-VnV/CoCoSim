function display_LOG_Messages(html_path, errors_list, warnings_list, debug_list, mode_display)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if mode_display
        Errors = HtmlItem('Errors list:', ...
            cellfun(@(x) HtmlItem(x, {}, 'black', 'red'),...
            errors_list, 'UniformOutput', false),...
            'black', 'black');
        Warnings = HtmlItem('Warning list:', ...
            cellfun(@(x) HtmlItem(x, {}, 'black'),...
            warnings_list, 'UniformOutput', false),...
            'black', 'black');
        Debugs = HtmlItem('Debug list:', ...
            cellfun(@(x) HtmlItem(x, {}, 'black'),...
            debug_list, 'UniformOutput', false),...
            'black', 'black');
        MenuUtils.createHtmlListUsingHTMLITEM('Log File',...
            {Errors, Warnings, Debugs}, html_path);
    else
        display_msg('Log information', MsgType.INFO, 'ToLustre', '');
        display_msg('Errors list:', MsgType.INFO, 'ToLustre', '');
        display_msg(MatlabUtils.strjoin(errors_list, '\n'), MsgType.ERROR, 'ToLustre', '');
        display_msg('Warning list:', MsgType.INFO, 'ToLustre', '');
        display_msg(MatlabUtils.strjoin(warnings_list, '\n'), MsgType.WARNING, 'ToLustre', '');
        display_msg('Debug list:', MsgType.INFO, 'ToLustre', '');
        display_msg(MatlabUtils.strjoin(debug_list, '\n'), MsgType.DEBUG, 'ToLustre', '');
    end
end


