function [results, numFail] = process_find_system_results(fsList,...
    title, varargin)
    % This function takes a list of objects (typically from a
    % find_system call) that failed a guide line criteria and creates an
    % HtmlItem with the failures as embedded sub HtmlItem with proper hyperlink
    % flist: list of failed HTML item with hyperlink
    % title: description of current guideline
    % varargin is used to pass isBlkPath, clearTitle to HtmlItem
    %   - isBlkPath will add hyperlink to HTML page to open the
    %     Simulink block that is not in compliance
    %   - cleanTitle will remove ( '<', '&lt;','>', '&gt;')
    %     from the title
    % if there is failure, the title will be red and the item(s)
    % will be added as collapsible list.
    % if there is no failure the title and any subtitles will be
    % green
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    numFail = numel(fsList);
    failList = cell(1,length(fsList));
    if iscell(fsList)
        for i=1:length(fsList)
            failList{i} =  HtmlItem(fsList{i},{},'red', '', varargin{:});
        end
    else
        for i=1:length(fsList)
            name = get_param(fsList(i), 'Name');
            parent = get_param(fsList(i), 'Parent');
            path = fullfile(parent, name);
            failList{i} =  HtmlItem(path,{},'red', '', varargin{:});
        end
    end

    if isempty(failList)
        results = HtmlItem(strcat(title, ': PASS'),...
            failList,'green', 'green');
    else
        results = HtmlItem(title, failList,'red','red');
    end

end

