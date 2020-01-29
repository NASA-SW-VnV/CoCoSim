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
function [report_path, status] = check_guidelines(model_path, varargin)
    % check_guidelines checks guidelines defined in guidelines_order script
    % This is a generic function that use guidelines_config as a configuration
    % file that decides which libraries to use and in which order to call the
    % checks functions.
    % See guidelines_config for more details.
    % Inputs:
    % model_path: The full path to Simulink model.
%    status = 0;

    mode_display = 1;
    for i=1:numel(varargin)
        if strcmp(varargin{i}, 'nodisplay')
            mode_display = 0;
            break;
        end
    end

    %% load the model
    [model_parent, model_base, ~] = fileparts(model_path);
    load_system(model_path);
    output_dir = fullfile(model_parent, 'cocosim_output', model_base);
    report_path = fullfile(output_dir, strcat(model_base, '_GUIDELINES.html'));
    if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end


    %% Order functions
    global ordered_guidelines_functions;
    if isempty(ordered_guidelines_functions)
        guidelines_config;
    end
    %% sort functions calls
    oldDir = pwd;
    warning off

    priority_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
    for i=1:numel(ordered_guidelines_functions)
        [dirname, func_name, ~] = fileparts(ordered_guidelines_functions{i});
        cd(dirname);
        fh = str2func(func_name);
        try
            display_msg(['runing ' func2str(fh)], MsgType.INFO, 'PP', '');
            [items_list_i, passed, priority] = fh(model_base);
            if passed
                %add it to the end of the list
                if isKey(priority_map, priority)
                    priority_map(priority) = [priority_map(priority), items_list_i];
                else
                    priority_map(priority) = items_list_i;
                end
            else
                if isKey(priority_map, priority)
                    priority_map(priority) = [items_list_i, priority_map(priority)];
                else
                    priority_map(priority) = items_list_i;
                end
            end
        catch me
            display_msg(['can not run ' func2str(fh)], MsgType.WARNING, 'PP', '');
            display_msg(me.getReport(), MsgType.DEBUG, 'PP', '');
            status = 1;
        end

    end
    items_list = {};
    if isKey(priority_map, 1)
        items_list{end+1} = HtmlItem('Mandatory', priority_map(1));
    end
    if isKey(priority_map, 2)
        items_list{end+1} = HtmlItem('Strongly Recommended', priority_map(2));
    end
    if isKey(priority_map, 3)
        items_list{end+1} = HtmlItem('Recommended', priority_map(3));
    end
    title = 'NASA Orion GN&C MATLAB/Simulink Standards';
    report_path = MenuUtils.createHtmlListUsingHTMLITEM(title, items_list, report_path, model_base);
    % warning on
    cd(oldDir);
    if mode_display
        open(report_path);
    end
    display_msg(['Report path: ' report_path], MsgType.RESULT, 'PP', '');
    display_msg('Done with the guidelines checking.', MsgType.INFO, 'PP', '');
end