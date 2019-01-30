classdef GuidelinesUtils
    %GUIDELINESUTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Static)
        function [results, numFail] = process_find_system_results(fsList,...
                title, description_text, varargin)
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
            
            description = HtmlItem(description_text, {}, 'black', 'black');
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
            
%             if isempty(failList)
%                 results = HtmlItem(strcat(title, ': PASS'),...
%                     {description,failList},'green', 'green');
%             else
%                 results = HtmlItem(title, {description,failList},'red','red');
%             end


            if isempty(failList)
                results = HtmlItem(strcat(title, ': PASS'),...
                    failList,'green', 'green');
            else
                results = HtmlItem(title, failList,'red','red');
            end

        end
        
        function allowedCharList = allowedChars(model,options)
            fsString = 'find_system(model, ''Regexp'', ''on''';
            for i=1:length(options)
                fsString = sprintf('%s, ''%s''',fsString, options{i});
            end
            fsString = sprintf('%s, ''Name'', ''\\W'');',fsString);
            fsList1 =  eval(fsString);
%             fsList1 =  find_system(model, 'Regexp', 'on','FindAll','on',...
%                 typeList{1},typeList{2}, 'Name', '\W');
            fsString = 'find_system(model, ''Regexp'', ''on''';
            for i=1:length(options)
                fsString = sprintf('%s, ''%s''',fsString, options{i});
            end
            fsString = sprintf('%s, ''Name'', ''^<\\w+>$'');',fsString);
            fsList2 =  eval(fsString);
%             fsList2 = find_system(model, 'Regexp', 'on','FindAll','on',...
%                 'type','line', 'Name', '^<\w+>$');
            allowedCharList = setdiff(fsList1, fsList2);
        end        
        
        function newList = ppSignalNames(list)
            % get names from handles
            Names = arrayfun(@(x) get_param(x, 'Name'), list, 'UniformOutput',...
                false);
            %remove empty lines
            list = list(~strcmp(Names, ''));
            %add parent
            newList = arrayfun(@(x) ...
                sprintf('%s in %s', ...
                HtmlItem.cleanSignalName(get_param(x, 'Name')), ...
                HtmlItem.addOpenCmd(get_param(x, 'Parent'))), ...
                list, 'UniformOutput', false);
        end
    end
end

