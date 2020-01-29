%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef HtmlItem < handle
    %MENUITEM Summary of this class goes here
    %   Detailed explanation goes here
%    
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

