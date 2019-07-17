%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ new_model_path, status ] = seal_tests(...
        model_full_path, exportToWs, mkHarnessMdl, nodisplay )
    %MCDCTOSIMULINK try to bring back the MC-DC conditions to simulink level.
    
    global  KIND2 Z3 LUSTRET LUSTREV LUCTREC_INCLUDE_DIR; 
    if isempty(KIND2)
        tools_config;
    end
    if ~exist(KIND2,'file')
        errordlg(sprintf('KIND2 model checker is not found in %s. Please set KIND2 path in tools_config.m', KIND2));
        status = 1;
        return;
    end
    status = BUtils.check_files_exist(LUSTRET, LUSTREV, LUCTREC_INCLUDE_DIR);
    if status
        msg = 'LUSTRET or LUSTREV not found, please configure "tools_config" file under tools folder';
        display_msg(msg, MsgType.ERROR, 'seal_tests', '');
        return;
    end
    
    if ~exist(model_full_path, 'file')
        display_msg(['File not foudn: ' model_full_path],...
            MsgType.ERROR, 'mutation_tests', '');
        return;
    else
        model_full_path = which(model_full_path);
    end
    if ~exist('exportToWs', 'var') || isempty(exportToWs)
        exportToWs = 0;
    end
    if ~exist('mkHarnessMdl', 'var') || isempty(mkHarnessMdl)
        mkHarnessMdl = 0;
    end
    if ~exist('nodisplay', 'var') || isempty(nodisplay)
        nodisplay = 0;
    end
    [model_parent_path, slx_file_name, ~] = fileparts(model_full_path);
    display_msg(['Generating mc-dc coverage Model for : ' slx_file_name],...
        MsgType.INFO, 'mutation_tests', '');
    status = 0;
    new_model_path = model_full_path;
    
    % Compile model
    try
        options = {};
        if nodisplay
            options{1} = nasa_toLustre.utils.ToLustreOptions.NODISPLAY;
        end
        [lus_full_path, xml_trace, is_unsupported, ~, ~, pp_model_full_path] = ...
            nasa_toLustre.ToLustre(model_full_path, [], ...
            LusBackendType.LUSTREC, CoCoBackendType.MCDC_TESTS_GEN, options{:});
        if is_unsupported
            display_msg('Model is not supported', MsgType.ERROR, 'validation', '');
            return;
        end
        [output_dir, lus_file_name, ~] = fileparts(lus_full_path);
        main_node = MatlabUtils.fileBase(lus_file_name);%remove .LUSTREC/.KIND2 from name.
        [~, slx_file_name, ~] = fileparts(pp_model_full_path);
        load_system(pp_model_full_path);
    catch ME
        display_msg(['Compilation failed for model ' slx_file_name], ...
            MsgType.ERROR, 'mcdcToSimulink', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
        return;
    end
    
    % generate seal file
    [seal_file, status] = LustrecUtils.generateLustrevSealFile(lus_full_path, output_dir, main_node, LUSTREV, LUCTREC_INCLUDE_DIR);
    if status
        return;
    end
    % Generate MCDC lustre file from Simulink model Lustre file
    try
        mcdc_file = LustrecUtils.generate_MCDCLustreFile(seal_file, output_dir);
    catch ME
        display_msg(['MCDC generation failed for lustre file ' lus_full_path],...
            MsgType.ERROR, 'mcdcToSimulink', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
        return;
    end
    
    try
        % generate test cases that covers the MC-DC conditions
        new_mcdc_file = LustrecUtils.adapt_lustre_file(mcdc_file, LusBackendType.KIND2);
        [syntax_status, output] = Kind2Utils2.checkSyntaxError(new_mcdc_file, KIND2, Z3);
        if syntax_status
            display_msg(output, MsgType.DEBUG, 'seal_tests', '');
            display_msg('This model is not compatible for MC-DC generation.', MsgType.RESULT, 'mcdcToSimulink', '');
            status = 1;
            return;
        end
        [~, T] = Kind2Utils2.extractKind2CEX(new_mcdc_file, output_dir, main_node, ...
            ' --slice_nodes false --check_subproperties true ');
        
        if isempty(T)
            display_msg('No MCDC conditions were generated', MsgType.RESULT, 'mcdcToSimulink', '');
            return;
        end
        % add random test scenario with 100 steps, to compare the coverage.
        %TODO change input_struct from dataset to signals/time struct.
        %[ input_struct ] = random_tests( model_full_path, 100);
        %input_struct.node_name = main_node;
        %T = [input_struct, T];
        if exportToWs
            assignin('base', strcat(slx_file_name, '_mcdc_tests'), T);
            display_msg(['Generated test suite is saved in workspace under name: ' strcat(slx_file_name, '_mcdc_tests')],...
                MsgType.RESULT, 'mutation_tests', '');
        end
    catch ME
        display_msg(['MCDC coverage generation failed for lustre file ' mcdc_file],...
            MsgType.ERROR, 'mcdcToSimulink', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
        return;
    end
    
    %% Create harness model
    if ~mkHarnessMdl
        return;
    end
    
    % create new model
    % we add a Postfix to differentiate it with the original Simulink model
    new_model_name = strcat(slx_file_name,'_seal');
    new_model_path = fullfile(output_dir, strcat(new_model_name,'.slx'));
    
    display_msg(['Seal model path: ' new_model_path ], MsgType.INFO, 'mcdcToSimulink', '');
    
    if exist(new_model_path,'file')
        if bdIsLoaded(new_model_name)
            close_system(new_model_name,0)
        end
        delete(new_model_path);
    end
    
    load_system(model_full_path);
    close_system(new_model_path,0)
    save_system(slx_file_name, new_model_path, 'OverwriteIfChangedOnDisk', true);
    load_system(new_model_path);
    
    % Create harness model
    try
        new_model_path = SLXUtils.makeharness(T, new_model_name, model_parent_path, '_harness');
        close_system(new_model_name, 0)
        if ~nodisplay
            open(new_model_path);
        end
    catch ME
        display_msg('Create harness model failed', MsgType.ERROR, 'mcdcToSimulink', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
        status = 1;
    end
end
