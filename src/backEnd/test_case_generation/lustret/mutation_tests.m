function [ T,  harness_model_name, status] = mutation_tests( model_full_path,...
    nb_steps, IMIN, IMAX, max_nb_test, min_coverage, exportToWs, mkHarnessMdl )
    %mutation_tests Summary of this function goes here
    %   Detailed explanation goes here
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    status = 0;
    if ~exist(model_full_path, 'file')
        display_msg(['File not foudn: ' model_full_path],...
            MsgType.ERROR, 'mutation_tests', '');
        status = 1;
        return;
    else
        model_full_path = which(model_full_path);
    end
    [model_path, slx_file_name, ~] = fileparts(model_full_path);
    display_msg(['Generating mutation based tests for : ' slx_file_name],...
        MsgType.INFO, 'mutation_tests', '');
    if ~exist('nb_steps', 'var') || isempty(nb_steps)
        nb_steps = 100;
    end
    if ~exist('IMAX', 'var') || isempty(IMAX)
        IMAX = 100;
    end
    if ~exist('IMIN', 'var') || isempty(IMIN)
        IMIN = -100;
    end
    if ~exist('max_nb_test', 'var') || isempty(max_nb_test)
        max_nb_test = 100;
    end
    if ~exist('min_coverage', 'var') || isempty(min_coverage)
        min_coverage = 95;
    end
    if ~exist('exportToWs', 'var') || isempty(exportToWs)
        exportToWs = 0;
    end
    if ~exist('mkHarnessMdl', 'var') || isempty(mkHarnessMdl)
        mkHarnessMdl = 0;
    end
    addpath(model_path);
    load_system(model_full_path);
    %% Compile model
    [lus_full_path, xml_trace, is_unsupported, ~, ~, pp_model_full_path] = ...
        nasa_toLustre.ToLustre(model_full_path, [], 'KIND2');
    if is_unsupported
        display_msg('Model is not supported', MsgType.ERROR, 'validation', '');
        return;
    end
    [output_dir, lus_file_name, ~] = fileparts(lus_full_path);
    node_name = MatlabUtils.fileBase(lus_file_name);%remove .LUSTREC/.KIND2 from name.
    [ T, ~, status ] = lustret_test_mutation( pp_model_full_path, ...
        lus_full_path, ...
        xml_trace, ...
        node_name,...
        nb_steps,...
        IMIN, ...
        IMAX,...
        'KIND2', ...
        1000, ...
        max_nb_test,...
        min_coverage );

    %%
    if exportToWs
        assignin('base', strcat(slx_file_name, '_mutation_tests'), T);
        display_msg(['Generated test suite is saved in workspace under name: ' strcat(slx_file_name, '_mutation_tests')],...
            MsgType.RESULT, 'mutation_tests', '');
    end

    %%
    harness_model_name = '';
    if mkHarnessMdl
        if ~exist(output_dir, 'dir'), mkdir(output_dir); end
        harness_model_name = SLXUtils.makeharness(T, slx_file_name, output_dir, '_mutations');
    end
end

