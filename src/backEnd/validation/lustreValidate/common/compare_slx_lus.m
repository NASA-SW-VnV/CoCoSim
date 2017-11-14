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
%           function. It generate test vectors that covers mutations inserted on
%           Lustre code.
%   tests_method == 3: Use equivalence checking following these steps:
%           1- Generate Simulink model SLX2 from original Lustre file using EMF
%           backend.
%           2- Create Simulink model containing both SLX1 and SLX2
%           3- Prove SLX1 <=> SLX2 Using Simulink Design Verifier. If the
%           user does not have SLDV we use CoCoSim to prove the property.
%   tests_method == 4: We generate Simulink model from the lustre file
%           using Lus2SLX and then compile it to Lus2 file using CoCosim.
%           We prove Lus1 <=> Lus2 using compositional verification

if ~exist('show_models', 'var')
    show_models = 0;
elseif show_models
    open(model_full_path);
end

if ~exist('tests_method', 'var') || isempty(tests_method)
    tests_method = 1;
end
if ~exist('model_checker', 'var') || isempty(model_checker)
    model_checker = 'KIND2';
end
%% define configuration variables

assignin('base', 'SOLVER', 'V');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
OldPwd = pwd;

valid = -1;
lustrec_failed = -1;
lustrec_binary_failed = -1;
sim_failed = -1;
%%
if tests_method ~= 4
    if isempty(model_full_path)
        [status, model_full_path, ~, ~] = LustrecUtils.construct_EMF_model(...
            lus_file_path, node_name, output_dir);
        if status
            return;
        end
    end
    [model_path, slx_file_name, ~] = fileparts(char(model_full_path));
    addpath(model_path);
    load_system(model_full_path);
    %% Get model inports informations
    [inports, inputEvents_names] = SLXUtils.get_model_inputs_info(model_full_path);
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end





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
if (tests_method == 3)
    [status, emf_model_path] = LustrecUtils.construct_EMF_verif_model(slx_file_name,...
        lus_file_path, node_name, output_dir);
    [verif_dir, verif_name, ~] = fileparts(emf_model_path);
    if status
        return;
    end
    %3- Prove SLX1 <=> SLX2.
    if  (tests_method == 3) && license('test', 'Simulink_Design_Verifier')
        
        opts = sldvoptions;
        opts.Mode = 'PropertyProving';
        opts.MaxProcessTime = 600;
        opts.SaveHarnessModel = 'on';
        opts.SaveReport = 'on';
        if ~show_models
            opts.DisplayReport = 'off';
        end
        opts.HarnessModelFileName = ...
            fullfile(verif_dir, strcat(verif_name,'_harness.slx'));
        opts.ProvingStrategy = 'ProveWithViolationDetection';
        opts.MaxViolationStep = 100;
        [status,FILENAMES] = sldvrun(verif_name, opts);
        if status ~= 1
            display_msg('Simulink Design Verifier Failed', MsgType.ERROR, 'validation', '');
            return;
        end
        sldvData = load(FILENAMES.DataFile);
        sldvData = sldvData.sldvData;
        if strcmp(sldvData.Objectives.status, 'Proven valid')
            valid = 1;
            msg = sprintf('Translation for model "%s" is valid \n',slx_file_name);
            display_msg(msg, MsgType.RESULT, 'COMPARE_SLX_LUS', '');
        elseif strcmp(sldvData.Objectives.status, 'Falsified')
            f_msg = sprintf('translation for model "%s" is not valid \n',slx_file_name);
            display_msg(f_msg, MsgType.RESULT, 'validation', '');
            f_msg = sprintf('Find the counter example in "%s":\n', opts.HarnessModelFileName);
            display_msg(f_msg, MsgType.RESULT, 'validation', '');
        end
        msg = sprintf('Verification model : %s', emf_model_path);
        display_msg(msg, MsgType.RESULT, 'validation', '');
        
    else
        msg = ['Method 3 with CoCosim is not supported yet/'...
            'Methode 3 works only with Simulink Design Verifier license for the moment.'];
        display_msg(msg, MsgType.ERROR, 'COMPARE_SLX_LUS', '');
    end
elseif (tests_method == 4) %4- Prove LUS1 <=> LUS2.
    clear lus2slx
    [status, emf_model_path, emf_path, EMF_trace_xml] = LustrecUtils.construct_EMF_model(...
        lus_file_path, node_name, output_dir);
    if status
        return;
    end

    msg = sprintf('EMF model : %s', emf_model_path);
    display_msg(msg, MsgType.DEBUG, 'validation', '');
    msg = sprintf('EMF traceability : %s', EMF_trace_xml.xml_file_path);
    display_msg(msg, MsgType.DEBUG, 'validation', '');
    
    [coco_lus_fpath, ~, ~, ~, ~, cocosim_trace, ~]=lustre_compiler(emf_model_path, [], 1);
%     cocosim_trace = '/Users/hbourbou/Documents/cocoteam/nfm2018/lustre_benchmarks/tcm/tmp/lustre_files/src_tcm_PP_EMF_PP/tcm_PP_EMF_PP.cocosim.trace.xml';
%     coco_lus_fpath = '/Users/hbourbou/Documents/cocoteam/nfm2018/lustre_benchmarks/tcm/tmp/lustre_files/src_tcm_PP_EMF_PP/tcm_PP_EMF_PP.lus';
    [verif_lus_path, nodes_list] = LustrecUtils.create_emf_verif_file(...
        lus_file_path,...
        coco_lus_fpath,...
        emf_path,...
        EMF_trace_xml, ...
        cocosim_trace);
    msg = sprintf('LUSTRE VERIFICATION File : %s', verif_lus_path);
    display_msg(msg, MsgType.DEBUG, 'validation', '');
    
%     verif_lus_path = which('fullrosace_bloc_Mdl_prelude_Flight_Dyn_PP_verif.lus');
%     nodes_list = { 'Flight_Dyn_Vert_Speed_Vz',...
%         'Flight_Dyn_Pitch_Rate_q', 'Flight_Dyn_Norm_Acc_az'};
    valid = []; IN_struct ={};
    parfor i=1:numel(nodes_list)
        msg = sprintf('Checking Node %s', nodes_list{i});
        display_msg(msg, MsgType.INFO, 'validation', '');
        [valid_i, IN_struct_i, ~] = ...
            LustrecUtils.run_comp_modular_verif_using_Kind2(...
            verif_lus_path, output_dir, nodes_list{i});
        valid(i) = valid_i;
        IN_struct{i} = IN_struct_i;
    end
    if prod(cellfun(@isempty, IN_struct)) ~= 1
        json_text = jsonencode(IN_struct);
        json_text = regexprep(json_text, '\\/','/');
        fname = fullfile(output_dir, 'CounterExamples_tmp.json');
        fname_formatted = fullfile(output_dir, 'CounterExamples.json');
        fid = fopen(fname, 'w');
        if fid==-1
            display_msg(['Couldn''t create file ' fname], MsgType.ERROR, 'compare_slx_lus', '');
        else
            fprintf(fid,'%s\n',json_text);
            fclose(fid);
            cmd = ['cat ' fname ' | python -mjson.tool > ' fname_formatted];
            try
                [status, output] = system(cmd);
                if status~=0
                    display_msg(['file is not formatted ' output], MsgType.ERROR, 'Stateflow_IRPP', '');
                    fname_formatted = fname;
                end
            catch
                fname_formatted = fname;
            end
        end
        msg = sprintf('Counter examples path: %s', fname_formatted);
        display_msg(msg, MsgType.RESULT, 'validation', '');
    end
end
cd(OldPwd)


end
