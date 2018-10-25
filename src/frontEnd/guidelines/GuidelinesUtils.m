classdef GuidelinesUtils
    %GUIDELINESUTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Static)
        function [results, numFail] = process_find_system_results(fsList,title, varargin)
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
    end
end

