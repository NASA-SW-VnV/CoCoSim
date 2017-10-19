function [valid, ...
    lustrec_failed, ...
    lustrec_binary_failed,...
    sim_failed] ...
    = compare_slx_lus(model_full_path,...
    lus_file_path, ...
    node_name, ...
    output_dir, ...
    tests_method, ...
    model_checker, ...
    show_models,...
    min_max_constraints)
%compare_slx_lus compare lustre file and Simulink model based on different
%test methods:
%   tests_method == 1: Use one random vector test of 100 steps.
%   tests_method == 2: Use vector tests using lustret_test_mutation
%   function. It generate test vectors that covers mutations inserted on
%   Lustre code.
%   tests_method == 3: Use equivalence checking following these steps:
%           1- Generate Simulink model from original Lustre file using EMF
%           backend.
%           2- Generate Lustre file 2 from Simulink model of step 1 using
%           CoCoSim.
%           3- Prove original Lustre <=> Lustre file of step 2.

if ~exist('show_models', 'var')
    show_models = 0;
elseif show_models
    open(model_full_path);
end

if ~exist('tests_method', 'var')
    tests_method = 1;
end
if ~exist('model_checker', 'var')
    model_checker = 'KIND2';
end
%% define configuration variables

assignin('base', 'SOLVER', 'V');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
OldPwd = pwd;


%%
[model_path, slx_file_name, ~] = fileparts(char(model_full_path));
addpath(model_path);
load_system(model_full_path);


if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end



%% Get model inports informations
[inports, inputEvents_names] = SLXUtils.get_model_inputs_info(model_full_path);

%% Create the input struct for the simulation
nb_steps = 100;
if exist('min_max_constraints','var') && numel(min_max_constraints) > 0
    IMIN = min_max_constraints{:,2};
    IMAX = min_max_constraints{:,3};
else
    IMIN = -100;
    IMAX = 100;
end
eps = 1e-5;
T = [];
%% equivalence testing
if tests_method == 2
    [ T, coverage_percentage ] = lustret_test_mutation( model_full_path, ...
        lus_file_path, ...
        node_name,...
        nb_steps,...
        IMIN, ...
        IMAX,...
        model_checker);
    if isempty(T)
        display_msg(sprintf('Mutation testing has failed.'), ...
            MsgType.INFO, 'compare_slx_lus', '');
        display_msg(sprintf('Using random vector test instead of Mutation testing'), ...
            MsgType.INFO, 'compare_slx_lus', '');
    else
        display_msg(sprintf('Test coverage is %f',coverage_percentage), ...
            MsgType.INFO, 'compare_slx_lus', '');
    end
end
if tests_method == 1 || tests_method == 2
    [input_struct, ~, ~] = SLXUtils.get_random_test(slx_file_name, inports, inputEvents_names, nb_steps,IMAX, IMIN);
    T = [T, input_struct];
    
    for i=1:numel(T)
        [valid,...
            lustrec_failed, ...
            lustrec_binary_failed,...
            sim_failed, ...
            done] = ...
            LustrecUtils.run_comparaison(slx_file_name, ...
            lus_file_path,...
            node_name, ...
            T(i),...
            output_dir,...
            'input_values', ...
            'outputs_values', ...
            eps, ...
            show_models);
        
        if done
            %% report
            f_msg = '\n Simulation Input (workspace) input_struct \n';
            f_msg = [f_msg 'Simulation Output (workspace) : yout_signals \n'];
            f_msg = [f_msg 'LustreC binary Input ' fullfile(output_dir,'input_values') '\n'];
            f_msg = [f_msg 'LustreC binary Output ' fullfile(output_dir,'outputs_values') '\n'];
            display_msg(f_msg, MsgType.RESULT, 'validation', '');
        end
        if ~valid
            break;
        end
    end
    
end
%% equivalence checking
if tests_method == 3
    tools_config;
    status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
    if status
        return;
    end
    %1- Generate Simulink model from original Lustre file using EMF
    %backend.
    
    %generate emf json
    [emf_path, status] = ...
        LustrecUtils.generate_emf(lus_file_path, output_dir, ...
        LUSTREC, LUCTREC_INCLUDE_DIR);
    if status
        return;
    end
    
    %generate simulink model
    [status, translated_nodes_path, trace_file_name] = lus2slx(emf_path, output_dir);
    %2- Generate Lustre file 2 from Simulink model of step 1 using
    %CoCoSim.
    
    % 3- Prove original Lustre <=> Lustre file of step 2 using
    %Compositional verification.
end
cd(OldPwd)


end
