classdef HtmlItem < handle
    %MENUITEM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        title
        subtitles
        colorMap
        color
    end
    
    methods
        function obj = HtmlItem(title, subtitles, color)
            obj.title = title;
            if nargin < 2
                obj.subtitles = {};
            elseif iscell(subtitles)
                obj.subtitles = subtitles;
            else
                obj.subtitles = {subtitles};
            end
            if nargin < 3 || isempty(color)
                obj.colorMap = containers.Map('KeyType', 'int32', 'ValueType', 'char');
                obj.colorMap(4) = 'black';
                obj.colorMap(5) = 'blue';
                obj.colorMap(6) = 'red';
                obj.color = '';
            else
                obj.color = color;
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
            if isempty(obj.color)
                Acolor = obj.colorMap(level);
            else
                Acolor = obj.color;
            end
            if isempty(obj.subtitles)
                res = sprintf('<li class="collection-item"><div class="%s-text text-darken-2">%s</div></li>', ...
                    Acolor, obj.title);
            else
                resCell = cell(numel(obj.subtitles) + 1, 1);
                resCell{1} = sprintf('<li class="collection-header"><div class="%s-text text-darken-2"><h%d>%s</h%d></div></li>', ...
                    Acolor,level, obj.title, level);
                for i=1:numel(obj.subtitles)
                    resCell{i+1} = obj.subtitles{i}.print(level + 1);
                end
                res = MatlabUtils.strjoin(resCell, '\n');
            end
        end
    end
end

