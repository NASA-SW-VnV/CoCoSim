function [ T, coverage_percentage ] = lustret_test_mutation( model_full_path, ...
    lus_full_path, ...
    traceability_path,...
    node_name,...
    nb_steps,...
    IMIN, ...
    IMAX,...
    model_checker, ...
    nb_mutants_max, ...
    MAX_nb_test,...
    Min_coverage )
%LUSTRET_TEST_MUTATION generates test suite based on mutations inserted in
%Lustre file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = [];
coverage_percentage = 0;
if nargin < 2
    print_help_messsage();
    return;
end
[lus_dir, lus_file_name, ~] = fileparts(lus_full_path);
[~, slx_file_name, ~] = fileparts(model_full_path);

if  ~exist('node_name', 'var')|| isempty(node_name)
    node_name = lus_file_name;
end
if  ~exist('nb_steps', 'var')|| isempty(nb_steps)
    nb_steps = 100;
end
if ~exist('IMAX', 'var')|| isempty(IMAX)
    IMAX = 1000;
end
if ~exist('IMIN', 'var')|| isempty(IMIN)
    IMIN = -1000;
end
if ~exist('MAX_nb_test', 'var')|| isempty(MAX_nb_test)
    MAX_nb_test = 3;
end
if ~exist('Min_coverage', 'var')|| isempty(Min_coverage)
    Min_coverage = 100;
end
if ~exist('model_checker', 'var') || isempty(model_checker)
    model_checker = 'KIND2';
end
if ~exist('nb_mutants_max', 'var')|| isempty(nb_mutants_max)
    nb_mutants_max = 500;
end
Pwd = pwd;

% get traceability Simulin -> Lustre
no_traceability = true;
if  ~exist('traceability_path', 'var')|| isempty(traceability_path)
    if exist(fullfile(lus_dir, strcat(lus_file_name, '.cocosim.trace.xml')), 'file')
        traceability_path = fullfile(lus_dir, strcat(lus_file_name, '.cocosim.trace.xml'));
        no_traceability = false;
    end
end
trace_xml = [];
if ~no_traceability
    try
        DOMNODE = xmlread(traceability_path);
    catch
        display_msg(...
            ['file ' cocosim_trace_file ' can not be read as xml file'],...
            MsgType.DEBUG,...
            'create_emf_verif_file', '');
        no_traceability = true;
    end
    trace_xml = DOMNODE.getDocumentElement;
end
%% generate mutations
[ err, output_dir] = lustret_mutation_generation( lus_full_path, nb_mutants_max );
% output_dir = fullfile(lus_file_dir, strcat(lus_file_name,'_mutants'));
% err = 0;
if err
    display_msg('Mutations generation has failed', MsgType.ERROR, 'lustret_test_mutation', '');
    cd(Pwd);
    return;
end
mutants_files = dir(fullfile(output_dir,strcat( lus_file_name, '.mutant.n*.lus')));
mutants_report = fullfile(output_dir,strcat( lus_file_name, '.mutation.json'));

mutants_files = mutants_files(~cellfun('isempty', {mutants_files.date}));
if isempty(mutants_files)
    display_msg(['No mutation has been found in ' output_dir], MsgType.ERROR, 'lustret_test_mutation', '');
    cd(Pwd);
    return;
end

%% create verification file compile to C binary all mutations
tools_config;
status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
if status
    msg = 'LUSTREC not found, please configure tools_config file under tools folder';
    display_msg(msg, MsgType.ERROR, 'lustret_test_mutation', '');
    cd(Pwd);
    return;
end
mutants_paths = {};
if ~exist(mutants_report, 'file')
    mutants_paths = cellfun(@(y) [output_dir filesep y], {mutants_files.name}, 'UniformOutput', false);
else
    load_system(model_full_path);
    node_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
    mutants_summary = BUtils.read_json(mutants_report);
    for i=1:numel(mutants_files)
        node_id = mutants_summary.(mutants_files(i).name).node_id;
        if isKey(node_map, node_id)
            simulink_block_name = node_map(node_id);
        else
            simulink_block_name =...
                XMLUtils.get_Simulink_block_from_lustre_node_name(...
                trace_xml, ...
                node_id, ...
                slx_file_name);
            node_map(node_id) = simulink_block_name;
        end
        blk_type = '';
        if ~strcmp(simulink_block_name, '')
            try
                blk_type = get_param(simulink_block_name, 'MaskType');
            catch
            end
            % do not include mutations inserted in properties nodes
            if ~strcmp(blk_type, 'Observer')
                mutants_paths{numel(mutants_paths) + 1} = fullfile(output_dir, mutants_files(i).name);
            end
        end
        
    end
end
if isempty(mutants_paths)
    display_msg(['No mutation has been generated for ' slx_file_name], MsgType.RESULT, 'lustret_test_mutation', '');
    cd(Pwd);
    return;
end
node_name_mutant = strcat(node_name, '_mutant');
% get main node signature
main_node_struct = LustrecUtils.extract_node_struct(lus_full_path, node_name, LUSTREC, LUCTREC_INCLUDE_DIR);

verification_files = {};
nb_err = 0;
for i=1:numel(mutants_paths)
    display_msg(['Generating C binary of mutant number ' num2str(i) ], MsgType.INFO, 'lustret_mutation_generation', '');
    mutant_file_path = mutants_paths{i};
    try
        verif_lus_path = LustrecUtils.create_mutant_verif_file(lus_full_path, mutant_file_path, main_node_struct, node_name, node_name_mutant);
    catch
        continue;
    end
    [Verif_dir, ~, ~] = fileparts(verif_lus_path);
    err = LustrecUtils.compile_lustre_to_Cbinary(verif_lus_path, 'top_verif' ,Verif_dir,  LUSTREC,LUCTREC_INCLUDE_DIR);
    if err
        nb_err = nb_err + 1;
        if nb_err >= 4
            return;
        end
        continue;
    else
        nb_err = nb_err - 1;
    end
    verification_files{numel(verification_files) + 1} = verif_lus_path;
end

%% generate random tests
display_msg('Generating random tests', MsgType.INFO, 'lustret_mutation_generation', '');
nb_test = 0;
% Need to correct the following, We can not use Simulink model information
% if it has not the same input names as the lustre node.
% We keep taking information from Lustre code.
% if ~isempty(model_full_path)
%     [inports, inputEvents_names] = SLXUtils.get_model_inputs_info(model_full_path);
% else
inports = main_node_struct.inputs;
inputEvents_names = {};
% end
T = [];
nb_verif = numel(verification_files);
coverage_percentage = 0;
nb_radnom_test = min(2, MAX_nb_test);
while (numel(verification_files) > 0 ) && (nb_test < nb_radnom_test) && (coverage_percentage < Min_coverage)
    display_msg(['running test number ' num2str(nb_test) ], MsgType.INFO, 'lustret_mutation_generation', '');
    [input_struct, ~, ~] = SLXUtils.get_random_test(slx_file_name, inports, inputEvents_names, nb_steps,IMAX, IMIN);
    lustre_input_values = LustrecUtils.getLustreInputValuesFormat(input_struct, nb_steps);
    good_test = false;
    for i=1:numel(verification_files)
        [binary_dir, verif_file_name, ~] = fileparts(verification_files{i});
        status = LustrecUtils.printLustreInputValues(lustre_input_values,...
            binary_dir, 'inputs_values');
        if status
            continue;
        end
        status = LustrecUtils.extract_lustre_outputs(verif_file_name,...
            binary_dir, 'top_verif', 'inputs_values', 'outputs_values');
        if status
            continue;
        end
        cd(binary_dir);
        txt  = fileread('outputs_values');
        if contains(txt, '''OK'': ''0''')
            verification_files{i} = '';
            good_test = true;
        end
    end
    nb_detected = numel(find(strcmp(verification_files, {''})));
    display_msg(['Test number ' num2str(nb_test) ' has detected ' num2str(nb_detected) ' mutants' ], MsgType.INFO, 'lustret_mutation_generation', '');
    verification_files = verification_files(~strcmp(verification_files, {''}));
    if good_test
        T = [T, input_struct];
    end
    nb_test = nb_test +1;
    coverage_percentage = 100*(nb_verif - numel(verification_files))/nb_verif;
    msg = sprintf('Mutants coverages is updated to %f percent', coverage_percentage);
    display_msg(msg, MsgType.INFO, 'lustret_mutation_generation', '');
end

%% Use model checker to find mutation CEX is exists

file_idx = 1;
while (file_idx <= numel(verification_files))  && (numel(T) < MAX_nb_test) && (coverage_percentage < Min_coverage)
    display_msg(['running model checker ' model_checker ' on file ' verification_files{file_idx} ], ...
        MsgType.INFO, 'lustret_mutation_generation', '');
    
    [~, input_struct, time_step] = LustrecUtils.run_verif(verification_files{file_idx}, inports, [], 'top_verif',  model_checker);
    if isempty(input_struct)
        file_idx = file_idx +1;
        continue;
    end
    lustre_input_values = LustrecUtils.getLustreInputValuesFormat(input_struct, time_step+1);
    good_test = false;
    name_parts = regexp(verification_files{file_idx}, '\.', 'split');
    last_part = name_parts{end-1};
    inputs_fname = strcat(last_part, 'inputs_values');
    outputs_fname = strcat(last_part, 'outputs_values');
    for i=1:numel(verification_files)
        [binary_dir, verif_file_name, ~] = fileparts(verification_files{i});
        status = LustrecUtils.printLustreInputValues(lustre_input_values,...
            binary_dir, inputs_fname);
        if status
            continue;
        end
        status = LustrecUtils.extract_lustre_outputs(verif_file_name,...
            binary_dir, 'top_verif', inputs_fname, outputs_fname);
        if status
            continue;
        end
        cd(binary_dir);
        txt  = fileread(outputs_fname);
        if contains(txt, '''OK'': ''0''')
            verification_files{i} = '';
            if i <= file_idx
                file_idx = file_idx - 1;
            end
            good_test = true;
        end
    end
    nb_detected = numel(find(strcmp(verification_files, {''})));
    display_msg(['Counter example ' num2str(file_idx) ' has detected ' num2str(nb_detected) ' mutants' ], MsgType.INFO, 'lustret_mutation_generation', '');
    verification_files = verification_files(~strcmp(verification_files, {''}));
    if good_test
        T = [T, input_struct];
    end
    file_idx = file_idx +1;
    coverage_percentage = 100*(nb_verif - numel(verification_files))/nb_verif;
    msg = sprintf('Mutants coverages is updated to %f percent', coverage_percentage);
    display_msg(msg, MsgType.INFO, 'lustret_mutation_generation', '');
end
nb_test = numel(T);
msg = sprintf('we generated %d random tests\n',nb_test);
msg = [msg sprintf('Only %d are good tests\n',numel(T))];
msg = [msg sprintf('Test cases coverages %f percent of generated mutations\n', coverage_percentage)];
display_msg(msg, MsgType.RESULT, 'lustret_mutation_generation', '');
msg = sprintf('files that has not been covered are :\n');
for i=1:numel(verification_files)
    msg = [msg sprintf('%s\n',verification_files{i})];
end
display_msg(msg, MsgType.DEBUG, 'lustret_mutation_generation', '');



cd(Pwd);
end

function print_help_messsage()
msg = 'LUSTRET_TEST_MUTATION is generating test cases based on mutations inserted in Lustre code\n';
msg = [msg, '\n   Usage: \n '];
msg = [msg, '\n     lustret_test_mutation( model_full_path, lus_full_path, [node_name], [nb_steps], [IMAX], [IMIN], [MAX_nb_test], [Min_coverage] ) \n\n '];
msg = [msg, '\t     model_full_path: is the full path of the Simulink model. \n'];
msg = [msg, '\t     lus_full_path: is the full path of the lustre file that correspond to the Simulink model. \n'];
msg = [msg, '\t     node_name: is the name of main node in Lustre file, if not given we use the name of the file. \n'];
msg = [msg, '\t     nb_steps: is the length of test vectors needed. By default we use 10 steps \n'];
msg = [msg, '\t     IMIN, IMAX: are the range of inputs,\n\t\t If given as scalars it means all inputs should be inside [IMIN, IMAX] interval.\n\t\t If given as vectors, it means IMAX(i) (resp IMIN(i)) is the maximum (resp minimum) value of input number i. \n'];
msg = [msg, '\t     MAX_nb_test: is the maximum of test vectors should be generated. By default we use 10 tests. \n'];
msg = [msg, '\t     Min_coverage: is the minimum coverage should be met of generated test vectors. By default we use 90%%. \n'];
cprintf('blue', msg);
end