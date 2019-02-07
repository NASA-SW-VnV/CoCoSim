
function [valid,...
        lustrec_failed, ...
        lustrec_binary_failed,...
        sim_failed, ...
        done] = ...
        run_comparaison(slx_file_name, ...
        lus_file_path,...
        node_name, ...
        input_dataSet,...
        output_dir,...
        input_file_name, ...
        output_file_name, ...
        eps, ...
        show_models)

    % define default outputs
    lustrec_failed=0;
    lustrec_binary_failed=0;
    sim_failed=0;
    valid = 0;
    done = 0;
    % define local variables
    OldPwd = pwd;
    if ~isa(input_dataSet, 'Simulink.SimulationData.Dataset')
        msg = sprintf('Input Signals should be of class Simulink.SimulationData.Dataset');
        display_msg(msg, MsgType.ERROR, 'LustrecUtils.run_comparaison', '');
        sim_failed = 1;
        return;
    end
    numberOfInports = numel(input_dataSet.getElementNames);
    if numberOfInports >= 1
        time = LustrecUtils.getTimefromDataset(input_dataSet);
        if isempty(time)
            msg = sprintf('Input Signals should be of class Simulink.SimulationData.Dataset');
            display_msg(msg, MsgType.ERROR, 'LustrecUtils.run_comparaison', '');
            sim_failed = 1;
            return;
        end
    else
        st = SLXUtils.getModelCompiledSampleTime(slx_file_name);
        time = (0:st:100)';
    end
    nb_steps = numel(time);
    if nb_steps >= 2
        simulation_step = time(2) - time(1);
    else
        simulation_step = 1;
    end
    stop_time = time(end);


    [lus_file_dir, lus_file_name, ~] = fileparts(char(lus_file_path));

    % Copile the lustre code to C
    tools_config;
    status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
    if status
        return;
    end
    err = LustrecUtils.compile_lustre_to_Cbinary(lus_file_path,...
        LusValidateUtils.name_format(node_name), ...
        output_dir, ...
        LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR);
    if err
        lustrec_failed = 1;
        return
    end

    % transform input_struct to Lustre format
    [lustre_input_values, status] = ...
        LustrecUtils.getLustreInputValuesFormat(input_dataSet, time);
    if status
        lustrec_failed = 1;
        return
    end
    % print lustre inputs in a file
    status = ...
        LustrecUtils.printLustreInputValues(...
        lustre_input_values, output_dir,  input_file_name);
    if status
        lustrec_binary_failed = 1;
        return
    end


    msg = sprintf('Simulating model "%s"\n',slx_file_name);
    display_msg(msg, MsgType.INFO, 'validation', '');
    GUIUtils.update_status('Simulating model');
    try
        % Simulate the model
        simOut = SLXUtils.simulate_model(slx_file_name, ...
            input_dataSet, ...
            simulation_step,...
            stop_time,...
            numberOfInports,...
            show_models);

        % extract lustre outputs from lustre binary
        status = LustrecUtils.extract_lustre_outputs(lus_file_name,...
            output_dir, ...
            node_name,...
            input_file_name, ...
            output_file_name);
        if status
            lustrec_binary_failed = 1;
            cd(OldPwd);
            return
        end

        % compare Simulin outputs and Lustre outputs
        GUIUtils.update_status('Compare Simulink outputs and lustrec outputs');

        yout = get(simOut,'yout');
        if ~isa(yout, 'Simulink.SimulationData.Dataset')
            f_msg = sprintf('Model "%s" shoud use Simulink.SimulationData.Dataset save format.',slx_file_name);
            display_msg(f_msg, MsgType.ERROR, 'validation', '');
            done = 0;
            return;
        end
        assignin('base','yout',yout);
        outputs_array = importdata(output_file_name,'\n');
        [valid, cex_msg, diff_name, diff] = ...
            LustrecUtils.compare_Simu_outputs_with_Lus_outputs(...
            input_dataSet, ...
            yout,...
            outputs_array, ...
            eps, ...
            time);



        if ~valid
            %% show the counter example
            GUIUtils.update_status('Translation is not valid');
            f_msg = sprintf('translation for model "%s" is not valid \n',slx_file_name);
            display_msg(f_msg, MsgType.RESULT, 'validation', '');
            f_msg = sprintf('Here is the counter example:\n');
            display_msg(f_msg, MsgType.RESULT, 'validation', '');
            t = datetime('now','Format','dd-MM-yyyy''@''HHmmss');
            cex_file_path = fullfile(lus_file_dir, ...
                strcat('cex_', char(t), '.txt'));
            LustrecUtils.show_CEX(cex_msg, cex_file_path );
            f_msg = sprintf('The difference between outputs %s is :%2.10f\%\n',diff_name, diff);
            display_msg(f_msg, MsgType.RESULT, 'CEX', '');
        else
            GUIUtils.update_status('Translation is valid');
            msg = sprintf('Translation for model "%s" is valid \n',slx_file_name);
            display_msg(msg, MsgType.RESULT, 'CEX', '');
        end
        cd(OldPwd);
    catch ME
        msg = sprintf('simulation failed for model "%s" :\n%s\n%s',...
            slx_file_name,ME.identifier,ME.message);
        display_msg(msg, MsgType.ERROR, 'validation', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
        sim_failed = 1;
        valid = 0;
        cd(OldPwd);
        return
    end
    done = 1;
end


