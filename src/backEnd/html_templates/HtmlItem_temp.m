classdef HtmlItem < handle
    %MENUITEM Summary of this class goes here
    %   Detailed explanation goes here
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
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
            obj.title = regexprep(title, '\n', '<br>');
            if removeHtmlKeywords
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
        
        function res = print(obj, level)
            if ~exist('level', 'var')
                level = 4;
            end
            if isempty(obj.text_color)
                Textcolor = obj.colorMap(level);
            else
                Textcolor = obj.text_color;
            end

            if isequal(obj.icon_color, 'red')
                    iconCode = sprintf('<i class="material-icons red-text"><h%d>do_not_disturb_on<h%d></i>', level, level);
            elseif isequal(obj.icon_color, 'green')
                iconCode = sprintf('<i class="material-icons green-text"><h%d>check_circle<h%d></i>', level, level);
            else
                iconCode = '';
            end            

            %             if isempty(obj.subtitles)
            dropDownCode = '';
            %             else
            %                 dropDownCode = sprintf('<i class="material-icons black-text"><h%d>arrow_drop_down<h%d></i>', level, level);
            %             end
            header =  sprintf('<div class="collapsible-header">%s<div class="%s-text text-darken-2"><h%d>%s</h%d></div>%s</div>\n', ...
                iconCode, Textcolor,level, obj.title, level, dropDownCode);
            if isempty(obj.subtitles)
                res = sprintf('<li>\n%s\n</li>', header);
            else
                res = sprintf('<li>\n%s\n<div class="collapsible-body">\n<div class="row">\n<div class="col s12 m12">\n<ul class="collapsible" >\n', ...
                    header);
                for i=1:numel(obj.subtitles)
                    res = [res ' ' obj.subtitles{i}.print(level + 1)];
                end
                res = [res, ' </ul>\n</div>\n</div>\n</div>\n</li>'];
            end
        end
        
        function res = print_noHTML(obj)
            lines{1} = obj.title;
            for i=1:numel(obj.subtitles)
                lines{end+1} = obj.subtitles{i}.print_noHTML();
            end
            res = MatlabUtils.strjoin(lines, '\n');
        end
    end
    methods(Static)
        function title = removeHtmlKeywords(title)
            title = strrep(title, '<', '&lt;');
            title = strrep(title, '>', '&gt;');
        end
        
        %%
        function htmlCmd = addOpenCmd(blk, shortName)
            if nargin < 2
                shortName = HtmlItem.removeHtmlKeywords(blk);
            end
            htmlCmd = sprintf('<a href="matlab:open_and_hilite_hyperlink (''%s'',''error'')">%s</a>', ...
                regexprep(blk, '\n', ' '),shortName);
        end
        function htmlCmd = addOpenFileCmd(blk, shortName)
            if nargin < 2
                shortName = HtmlItem.removeHtmlKeywords(blk);
            end
            htmlCmd = sprintf('<a href="matlab:open (''%s'')">%s</a>', ...
                regexprep(blk, '\n', ' '), shortName);
        end
        
        %%
        
        function displayErrorMessages(html_path, msg_list, mode_display)
            HtmlItem.displayMessages(html_path,'ERRORS LIST', msg_list, 'red', mode_display);
        end
        function displayWarningMessages(html_path, title, msg_list, mode_display)
            HtmlItem.displayMessages(html_path,title, msg_list, 'cyan', mode_display);
        end
        function displayMessages(html_path,title, msg_list, msgColor, mode_display)
            if mode_display
                htmlList = cellfun(@(x) HtmlItem(x, {}, 'black', msgColor),msg_list, 'UniformOutput', false);
                MenuUtils.createHtmlListUsingHTMLITEM(title, htmlList, html_path);
            else
                display_msg(title, MsgType.INFO, 'ToLustre', '');
                display_msg(MatlabUtils.strjoin(msg_list, '\n'), MsgType.ERROR, 'ToLustre', '');
            end
        end
        function display_LOG_Messages(html_path, errors_list, warnings_list, debug_list, mode_display)
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
    end
end

