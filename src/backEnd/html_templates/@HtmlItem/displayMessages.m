function displayMessages(html_path,title, msg_list, msgColor, mode_display)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if mode_display
        htmlList = cellfun(@(x) HtmlItem(x, {}, 'black', msgColor),msg_list, 'UniformOutput', false);
        MenuUtils.createHtmlListUsingHTMLITEM(title, htmlList, html_path);
    else
        display_msg(title, MsgType.INFO, 'ToLustre', '');
        display_msg(MatlabUtils.strjoin(msg_list, '\n'), MsgType.ERROR, 'ToLustre', '');
    end
end
