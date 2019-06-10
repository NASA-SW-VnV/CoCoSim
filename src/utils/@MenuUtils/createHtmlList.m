function html_path = createHtmlList(title, items_list, html_path)
    %% Create html page with title and items list.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    
    htmlList = cellfun(@(x) HtmlItem(x, {}, 'black', [], [], false),...
        items_list, 'UniformOutput', false);
    html_path = MenuUtils.createHtmlListUsingHTMLITEM(title, htmlList, html_path);
end
