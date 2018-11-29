classdef HtmlItem < handle
    %MENUITEM Summary of this class goes here
    %   Detailed explanation goes here
    
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
                isBlkPath, cleanTitle)
            if nargin <= 4 || isempty(isBlkPath)
                isBlkPath = false;
            end
            if nargin <= 5
                cleanTitle = true;
            end
            obj.title = title;
            if cleanTitle
                obj.title = HtmlItem.cleanTitle(obj.title);
            end
            if isBlkPath
                name = get_param(title, 'Name');
                parent = get_param(title, 'Parent');
                obj.title = sprintf('%s in <a href="matlab:open_and_hilite_hyperlink (''%s'',''error'')">%s</a>', name, title, parent);
                %obj.title = HtmlItem.addOpenCmd(obj.title);
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
            if isempty(obj.icon_color)
                iconCode = '';
            else
                if isequal(obj.icon_color, 'red')
                    iconCode = sprintf('<i class="material-icons red-text"><h%d>do_not_disturb_on<h%d></i>', level, level);
                else
                    iconCode = sprintf('<i class="material-icons green-text"><h%d>check_circle<h%d></i>', level, level);
                end
            end
            if isempty(obj.subtitles)
                dropDownCode = '';
            else
                dropDownCode = sprintf('<i class="material-icons black-text"><h%d>arrow_drop_down<h%d></i>', level, level);
            end
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
        function title = cleanTitle(title)
            title = strrep(title, '<', '&lt;');
            title = strrep(title, '>', '&gt;');
        end
        function htmlCmd = addOpenCmd(blk)
            htmlCmd = sprintf('<a href="matlab:open_and_hilite_hyperlink (''%s'',''error'')">%s</a>', blk, blk);
        end
    end
end

