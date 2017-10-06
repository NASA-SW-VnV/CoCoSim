function [ T, coverage_percentage ] = lustret_test_mutation( model_full_path, ...
                                                            lus_full_path, ...
                                                            node_name,...
                                                            nb_steps,...
                                                            IMIN, ...
                                                            IMAX,...
                                                            MAX_nb_test,...
                                                            Min_coverage,...
                                                            model_checker )
%LUSTRET_TEST_MUTATION Summary of this function goes here
%   Detailed explanation goes here


if nargin < 2
    print_help_messsage();
    return;
end
[~, lus_file_name, ~] = fileparts(lus_full_path);
[~, slx_file_name, ~] = fileparts(model_full_path);
if  ~exist('node_name', 'var')
    node_name = lus_file_name;
end
if  ~exist('nb_steps', 'var')
    nb_steps = 100;
end
if ~exist('IMAX', 'var')
    IMAX = 1000;
end
if ~exist('IMIN', 'var')
    IMIN = -1000;
end
if ~exist('MAX_nb_test', 'var')
    MAX_nb_test = 10;
end
if ~exist('Min_coverage', 'var')
    Min_coverage = 90;
end
if ~exist('model_checker', 'var')
    model_checker = 'KIND2';
end
Pwd = pwd;

%% generate mutations
[ err, output_dir] = lustret_mutation_generation( lus_full_path );
% output_dir = fullfile(lus_file_dir, strcat(lus_file_name,'_mutants'));
% err = 0;
if err
    display_msg('Mutations generation has failed', MsgType.ERROR, 'lustret_test_mutation', '');
    cd(Pwd);
    return;
end
mutants_files = dir(fullfile(output_dir,strcat( lus_file_name, '.mutant.n*.lus')));
mutants_files = mutants_files(~cellfun('isempty', {mutants_files.date})); 
if isempty(mutants_files)
    display_msg(['No mutation has been found in ' output_dir], MsgType.ERROR, 'lustret_test_mutation', '');
    cd(Pwd);
    return;
end

%% create verification file compile to C binary all mutations
tools_config;
if ~exist('LUSTREC','var')
    display_msg('Lustrec compiler is not declared in tools_config file', MsgType.ERROR, 'lustret_mutation_generation', '');
    cd(Pwd);
    return;
end
if ~exist('LUCTREC_INCLUDE_DIR','var')
    display_msg('LUCTREC_INCLUDE_DIR variable is not declared in tools_config file', MsgType.ERROR, 'lustret_mutation_generation', '');
    cd(Pwd);
    return;
    
end
mutants_paths = cellfun(@(x,y) [x '/' y], {mutants_files.folder}, {mutants_files.name}, 'UniformOutput', false);
node_name_mutant = strcat(node_name, '_mutant');
% get main node signature
main_node_struct = LustrecUtils.extract_node_struct(lus_full_path, node_name, LUSTREC, LUCTREC_INCLUDE_DIR);

verification_files = {};
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
        continue;
    end
    verification_files{numel(verification_files) + 1} = verif_lus_path;
end

%% generate random tests
display_msg('Generating random tests', MsgType.INFO, 'lustret_mutation_generation', '');
nb_test = 0;
if ~isempty(model_full_path)
    [inports, inputEvents_names] = SLXUtils.get_model_inputs_info(model_full_path);
else
    inports = main_node_struct.inputs;
    inputEvents_names = {};
end
T = [];
nb_verif = numel(verification_files);
coverage_percentage = 0;
while (numel(verification_files) > 0 ) && (nb_test < MAX_nb_test) && (coverage_percentage < Min_coverage)
    display_msg(['running test number ' num2str(nb_test) ], MsgType.INFO, 'lustret_mutation_generation', '');
    [input_struct, lustre_input_values, ~, ~] = SLXUtils.get_random_test(slx_file_name, inports, inputEvents_names, nb_steps,IMAX, IMIN);
    
    good_test = false;
    for i=1:numel(verification_files)
        [binary_dir, verif_file_name, ~] = fileparts(verification_files{i});
        print_lus_input_values(binary_dir, lustre_input_values);
        extract_outputs(verif_file_name);
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
nb_test = numel(T);
file_idx = 1;
while (numel(verification_files) > 0 ) && (nb_test < MAX_nb_test) && (coverage_percentage < Min_coverage)
    display_msg(['running model checker ' model_checker ' on file ' verification_files{file_idx} ], ...
        MsgType.INFO, 'lustret_mutation_generation', '');
    [input_struct, lustre_input_values, ~, ~] = LustrecUtils.run_verif(verification_files{file_idx},'', 'top_verif',  model_checker);
    
    good_test = false;
    for i=1:numel(verification_files)
        [binary_dir, verif_file_name, ~] = fileparts(verification_files{i});
        print_lus_input_values(binary_dir, lustre_input_values);
        extract_outputs(verif_file_name);
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

fprintf('we generated %d random tests\n',nb_test);
fprintf('Only %d are good tests\n',numel(T));
fprintf('Test cases coverages %f%% of generated mutations\n', coverage_percentage);
fprintf('files that has not been covered are :\n');
for i=1:numel(verification_files)
    fprintf('%s\n',verification_files{i});
end
%%

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








function print_lus_input_values(output_dir, lustre_input_values)
%% print lustre inputs in a file
cd(output_dir)
values_file = fullfile(output_dir, 'input_values');
fid = fopen(values_file, 'w');
for i=1:numel(lustre_input_values)
    value = [num2str(lustre_input_values(i),'%.20f') '\n'];
    fprintf(fid, value);
end
fclose(fid);
end

function extract_outputs(lus_file_name)
lustre_binary = strcat(lus_file_name,'_top_verif');
command  = sprintf('./%s  < input_values > outputs_values',lustre_binary);
[status, binary_out] =system(command);
if status
    err = sprintf('lustrec binary failed for model "%s"',lus_file_name,binary_out);
    display_msg(err, MsgType.ERROR, 'validation', '');
    display_msg(err, MsgType.DEBUG, 'validation', '');
    display_msg(binary_out, MsgType.DEBUG, 'validation', '');
end
end
