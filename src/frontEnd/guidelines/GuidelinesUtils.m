classdef GuidelinesUtils
    %GUIDELINESUTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Static)
        function [results, numFail] = process_find_system_results(fsList,...
                title, varargin)
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
            numFail = numel(fsList);
            failList = cell(1,length(fsList));
            if iscell(fsList)
                for i=1:length(fsList)
                    failList{i} =  HtmlItem(fsList{i},{},'red', '', varargin{:});
                end
            else
                for i=1:length(fsList)
                    name = get_param(fsList(i), 'Name');
                    failList{i} =  HtmlItem(name,{},'red', '', varargin{:});
                end
            end
            if isempty(failList)
                results = HtmlItem(strcat(title, ': PASS'),...
                    failList,'green', 'green');
            else
                results = HtmlItem(title, failList,'red','red');
            end
        end
        
        function allowedCharList = allowedChars_lineType(model)
            % 
            fsList1 =  find_system(model, 'Regexp', 'on','FindAll','on',...
                'type','line', 'Name', '\W');
            fsList2 = find_system(model, 'Regexp', 'on','FindAll','on',...
                'type','line', 'Name', '^<\w+>$');
            allowedCharList = setdiff(fsList1, fsList2);
        end
        
        function allowedCharList = allowedChars(model,typeList)
            % typeList is a list of 2 cells needed to define block/line
            % type
            fsList1 =  find_system(model, 'Regexp', 'on','FindAll','on',...
                typeList{1},typeList{2}, 'Name', '\W');
            fsList2 = find_system(model, 'Regexp', 'on','FindAll','on',...
                'type','line', 'Name', '^<\w+>$');
            allowedCharList = setdiff(fsList1, fsList2);
        end        
        
        function newList = ppList(list)
            % get names from handles
            Names = arrayfun(@(x) get_param(x, 'Name'), list, 'UniformOutput',...
                false);
            %remove empty lines
            list = list(~strcmp(Names, ''));
            %add parent
            newList = arrayfun(@(x) ...
                sprintf('%s in %s', ...
                HtmlItem.cleanTitle(get_param(x, 'Name')), ...
                HtmlItem.addOpenCmd(get_param(x, 'Parent'))), ...
                list, 'UniformOutput', false);
        end
    end
end

