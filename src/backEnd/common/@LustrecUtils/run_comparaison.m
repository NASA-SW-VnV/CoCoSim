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
% 

function [valid,...
        lustrec_failed, ...
        lustrec_binary_failed,...
        sim_failed, ...
        done, ...
        cex_file_path] = ...
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
    cex_file_path = '';
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
        if st > 0
            time = (0:st:100)';
        else
            time = (0:0.1:100)';
        end
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
        nasa_toLustre.utils.SLX2LusUtils.name_format(node_name), ...
        output_dir, ...
        LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR);
    if err
        lustrec_failed = 1;
        return
    end

    % transform input_struct to Lustre format
    [node_struct, status] = LustrecUtils.extract_node_struct(lus_file_path,...
                nasa_toLustre.utils.SLX2LusUtils.name_format(node_name), ...
                LUSTREC,...
                LUCTREC_INCLUDE_DIR);
    if status
        lustrec_failed = 1;
        return
    end
    [lustre_input_values, status] = ...
        LustrecUtils.getLustreInputValuesFormat(input_dataSet, time, node_struct);
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
    %GUIUtils.update_status('Simulating model');
    try
        % Simulate the model
        simOut = SLXUtils.simulate_model(slx_file_name, ...
            input_dataSet, ...
            simulation_step,...
            stop_time,...
            numberOfInports,...
            show_models);

        yout = get(simOut,'yout');
        if isempty(yout)
            f_msg = sprintf('Model "%s" has no Outport.',slx_file_name);
            display_msg(f_msg, MsgType.RESULT, 'validation', '');
            done = 0;
            sim_failed = 1;
            return;
        elseif ~isa(yout, 'Simulink.SimulationData.Dataset')
            f_msg = sprintf('Model "%s" shoud use Simulink.SimulationData.Dataset save format.',slx_file_name);
            display_msg(f_msg, MsgType.ERROR, 'validation', '');
            done = 0;
            return;
        end
        
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
        %GUIUtils.update_status('Compare Simulink outputs and lustrec outputs');

        
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
            %GUIUtils.update_status('Translation is not valid');
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
            %GUIUtils.update_status('Translation is valid');
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


