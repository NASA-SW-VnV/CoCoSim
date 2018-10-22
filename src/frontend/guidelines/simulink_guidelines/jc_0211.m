function [results, passed] = jc_0211(model)
    %4.3.4.1 jc_0211: Usable characters for Inport block and Outport block
    try
        model_full_path = MenuUtils.get_file_name(model) ;
        [parent, file_name, ~] = fileparts(model_full_path);
        [orion_gnc_check_results, passed] = jc_0211_helper(file_name);
        % display report
        % HTML report
        
        output_dir = fullfile(parent, 'cocosim_output', file_name);
        html_path = fullfile(output_dir, strcat(file_name, '_Orion_Simulink_guidelines.html'));
        if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end
        results = {};
        for i=1:length(orion_gnc_check_results)
            results{end+1} = sprintf('TEST %s:',orion_gnc_check_results{i}{1});
            if isempty(orion_gnc_check_results{i}{2})
                results{end+1} = '   PASS';
            else
                for j=1:length(orion_gnc_check_results{i}{2})
                    results{end+1} = sprintf('-- %s',orion_gnc_check_results{i}{2}{j});
                end
            end
        end
        
    catch ME
        display_msg(ME.getReport(), MsgType.DEBUG,'guidelinesMenu','');
        display_msg(ME.message, MsgType.ERROR,'guidelinesMenu','');
    end
end
function [results, passed] = jc_0211_helper(model)
    display_msg(sprintf('Check %s for compliance with NASA Orion GNC Simulink guidelines',model),...
        MsgType.INFO,'guidelinesMenu','');
    results = {};
    blocks = find_system(model);
    passed = true;
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
            passed = false;
        end
        % leading number in name
        TF = isstrprop(cur_name,'digit')
        if TF(1) == 1
            leading_number_in_name{end+1} = blocks{i};
            passed = false;
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