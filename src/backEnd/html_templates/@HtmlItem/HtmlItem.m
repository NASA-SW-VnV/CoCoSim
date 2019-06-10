classdef HtmlItem < handle
    %MENUITEM Summary of this class goes here
    %   Detailed explanation goes here
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        title  % string description of guideline being checked
        subtitles % list of HtmlItem for sub guideline results
        colorMap
        text_color % text for title color
        icon_color % collapsible icon color if there are subtitles
        isBlkPath  % Path to offending Simulink block
    end
    
    methods
        function obj = HtmlItem(title, subtitles, text_color, icon_color,...
                isBlkPath, removeHtmlKeywords)
            if nargin <= 4 || isempty(isBlkPath)
                isBlkPath = false;
            end
            if nargin <= 5
                removeHtmlKeywords = false;
            end
            if isBlkPath
                obj.title = regexprep(title, '\n', ' ');
            else
                obj.title = regexprep(title, '\n', '<br>');
            end
            if ~isBlkPath && removeHtmlKeywords
                obj.title = HtmlItem.removeHtmlKeywords(obj.title);
            end
            if isBlkPath
                %name = get_param(title, 'Name');
                %parent = get_param(title, 'Parent');
                %obj.title = sprintf('%s in <a href="matlab:open_and_hilite_hyperlink (''%s'',''error'')">%s</a>', name, title, parent);
                obj.title = HtmlItem.addOpenCmd(obj.title);
            end
            if nargin < 2
                obj.subtitles = {};
            elseif iscell(subtitles)
                obj.subtitles = subtitles;
            elseif numel(subtitles) > 1
                for i=1:numel(subtitles)
                    obj.subtitles{i} = subtitles(i);
                end
            else
                obj.subtitles = {subtitles};
            end
            if nargin < 3 || isempty(text_color)
                obj.colorMap = containers.Map('KeyType', 'int32', 'ValueType', 'char');
                obj.colorMap(4) = 'black';
                obj.colorMap(5) = 'blue';
                obj.colorMap(6) = 'red';
                obj.text_color = '';
            else
                obj.text_color = text_color;
            end
            if nargin < 4 || isempty(icon_color)
                obj.icon_color = '';
            else
                obj.icon_color = icon_color;
            end
        end
        function setTitle(obj, title)
            obj.title = title;
        end
        function setSubtitles(obj, subtitles)
            if iscell(subtitles)
                obj.subtitles = subtitles;
            else
                obj.subtitles = {subtitles};
            end
        end
        
        function setColor(obj, color)
            obj.color = color;
        end
        
        res = print(obj, level)
        
        res = print_noHTML(obj)

    end
    methods(Static)
        title = removeHtmlKeywords(title)
        
        htmlCmd = addOpenCmd(blk, shortName)

        htmlCmd = addOpenFileCmd(blk, shortName)

        displayErrorMessages(html_path, msg_list, mode_display)

        displayWarningMessages(html_path, title, msg_list, mode_display)

        displayMessages(html_path,title, msg_list, msgColor, mode_display)

        display_LOG_Messages(html_path, errors_list, warnings_list, debug_list, mode_display)

    end
end

