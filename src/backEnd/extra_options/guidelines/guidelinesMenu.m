%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Khanh Trinh 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function schema = guidelinesMenu(callbackInfo)
schema = sl_action_schema;
schema.label = 'Check model against guidelines ';
schema.callback = @guidelinesCallback;
end


function guidelinesCallback(callbackInfo)
try
    
    model_full_path = MenuUtils.get_file_name(gcs) ;
    [parent, file_name, ~] = fileparts(model_full_path);
    orion_gnc_check_results = check_orion_gnc_slx_guidelines(file_name);
    % display report
    % HTML report
    
    output_dir = fullfile(parent, 'cocosim_output', file_name);
    html_path = fullfile(output_dir, strcat(file_name, '_Orion_Simulink_guidelines.html'));
    if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end
    htmlList = {};
    for i=1:length(orion_gnc_check_results)
        htmlList{end+1} = sprintf('TEST %s:',orion_gnc_check_results{i}{1});
        if isempty(orion_gnc_check_results{i}{2})
            htmlList{end+1} = '   PASS';
        else
            for j=1:length(orion_gnc_check_results{i}{2})
                htmlList{end+1} = sprintf('-- %s',orion_gnc_check_results{i}{2}{j});
            end
        end
    end
        
    MenuUtils.createHtmlList('NASA Orion GN&C MATLAB/Simulink Standards', htmlList, html_path);
    msg = sprintf('HTML report is in : %s', html_path);
    display_msg(msg, MsgType.INFO, 'guidelinesMenu', '');
            
catch ME
    display_msg(ME.getReport(), MsgType.DEBUG,'guidelinesMenu','');
    display_msg(ME.message, MsgType.ERROR,'guidelinesMenu','');
end
end

function results = check_orion_gnc_slx_guidelines(model)
    display_msg(sprintf('Check %s for compliance with NASA Orion GNC Simulink guidelines',model),...
        MsgType.INFO,'guidelinesMenu','');
    results = {};
    blocks = find_system(model);
    
    % FILE AND DIRECTORY NAMING CONVENTION
    
    no_space_in_name = {};
    leading_number_in_name = {};
    leading_underscore_in_name = {};
    consecutive_underscore_in_name = {};
    ends_with_underscore_in_name = {};
    for i=1:length(blocks)        
        cur_name = get_param(blocks{i},'name');
        % space in name
        TF = isspace(cur_name);
        numSpace = sum(TF);
        fprintf('num space in %s is %d\n',cur_name,numSpace);
        if numSpace > 0
            no_space_in_name{end+1} = blocks{i};
        end
        % leading number in name
        TF = isstrprop(cur_name,'digit')
        if TF(1) == 1
            leading_number_in_name{end+1} = blocks{i};
        end
        % leading_underscore_in_name
        %TF = isstrprop(cur_name,'_');
    end
    results{end+1} = {'4.3.4.1 jc_0211: Usable characters for Inport block and Outport block - space_in_name', no_space_in_name};
    results{end+1} = {'4.3.4.1 jc_0211: Usable characters for Inport block and Outport block - leading_number_in_name', leading_number_in_name};
    results{end+1} = {'4.3.4.1 jc_0211: Usable characters for Inport block and Outport block - leading_underscore_in_name', leading_underscore_in_name};
    results{end+1} = {'4.3.4.1 jc_0211: Usable characters for Inport block and Outport block - consecutive_underscore_in_name', consecutive_underscore_in_name};
    results{end+1} = {'4.3.4.1 jc_0211: Usable characters for Inport block and Outport block - ends_with_underscore_in_name', ends_with_underscore_in_name};
        
end

