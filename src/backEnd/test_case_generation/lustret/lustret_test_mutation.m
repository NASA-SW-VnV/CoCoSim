function [ T ] = lustret_test_mutation( lus_full_path, node_name, nb_steps, IMAX, IMIN )
%LUSTRET_TEST_MUTATION Summary of this function goes here
%   Detailed explanation goes here
[~, file_name, ~] = fileparts(lus_full_path);
if nargin < 2
    node_name = file_name;
end
if nargin < 3
    nb_steps = 10;
end
if ~exist('IMAX', 'var')
    IMAX = 1000;
end
if ~exist('IMIN', 'var')
    IMIN = -1000;
end
Pwd = pwd;

%% generate mutations
[ err, output_dir] = lustret_mutation_generation( lus_full_path );

if err
    display_msg('Mutations generation has failed', MsgType.ERROR, 'lustret_test_mutation', '');
    cd(Pwd);
    return;
end
mutants_files = dir(fullfile(output_dir,strcat( file_name, '.mutant.n*.lus')));

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
main_node_struct = extract_main_node_struct(lus_full_path, node_name, LUSTREC, LUCTREC_INCLUDE_DIR);
verification_files = {};
for i=1:numel(mutants_paths)
    mutant_file_path = mutants_paths{i};
    try
        verif_lus_path = create_mutant_verif_file(lus_full_path, mutant_file_path, main_node_struct, node_name, node_name_mutant);
    catch
        continue;
    end
    [Verif_dir, ~, ~] = fileparts(verif_lus_path);
    err = compile_lustre_to_Cbinary(verif_lus_path, 'top_verif' ,Verif_dir,  LUSTREC,LUCTREC_INCLUDE_DIR);
    if err
        continue;
    end
    verification_files{numel(verification_files) + 1} = verif_lus_path;
end

%% generate random tests
nb_test = 0;
inports = main_node_struct.inputs;
T = [];
nb_verif = numel(verification_files);
while (numel(verification_files) > 0 ) && nb_test < 3
    fprintf('test number %d\n', nb_test);
    [input_struct, lustre_input_values] = get_random_test(inports, nb_steps, IMAX, IMIN);
    good_test = false;
    for i=1:numel(verification_files)
        [binary_dir, verif_file_name, ~] = fileparts(verification_files{i});
        print_lus_input_values(binary_dir, lustre_input_values);
        extract_outputs(verif_file_name);
        cd(binary_dir);
        txt  = fileread('outputs_values');
        if contains(txt, '0')
            verification_files{i} = '';
            good_test = true;
        end
    end
    verification_files = verification_files(~strcmp(verification_files, {''}));
    if good_test
        T = [T, input_struct];
    end
    nb_test = nb_test +1;
end

fprintf('we generated %d random tests\n',nb_test);
fprintf('Only %d are good tests\n',numel(T));
fprintf('Test cases coverages %f\% of generated mutations\n', 100*(nb_verif - numel(verification_files))/nb_verif);
fprintf('files that has not been covered are :\n');
for i=1:numel(verification_files)
    fprintf('%s\n',verification_files{i});
end
%%

cd(Pwd);
end

%% compile_lustre_to_Cbinary
function err = compile_lustre_to_Cbinary(lus_file_path, node_name, output_dir, LUSTREC,LUCTREC_INCLUDE_DIR)
[~, file_name, ~] = fileparts(lus_file_path);
% generate C code
command = sprintf('%s -I "%s" -d "%s" -node %s "%s"',LUSTREC,LUCTREC_INCLUDE_DIR, output_dir, node_name, lus_file_path);
msg = sprintf('LUSTREC_COMMAND : %s\n',command);
display_msg(msg, MsgType.INFO, 'lustret_test_mutation', '');
[status, lustre_out] = system(command);
err = 0;
if status
    display_msg(msg, MsgType.DEBUG, 'lustret_test_mutation', '');
    msg = sprintf('lustrec failed for model "%s"',lus_file_path);
    display_msg(msg, MsgType.ERROR, 'lustret_test_mutation', '');
    display_msg(msg, MsgType.DEBUG, 'lustret_test_mutation', '');
    display_msg(lustre_out, MsgType.DEBUG, 'lustret_test_mutation', '');
    err = 1;
    return
end

% generate C binary
cd(output_dir);
msg = sprintf('start compiling model "%s"\n',file_name);
display_msg(msg, MsgType.INFO, 'lustret_test_mutation', '');
makefile_name = fullfile(output_dir,strcat(file_name,'.makefile'));
command = sprintf('make -f "%s"', makefile_name);
msg = sprintf('MAKE_LUSTREC_COMMAND : %s\n',command);
display_msg(msg, MsgType.INFO, 'lustret_test_mutation', '');
[status, make_out] = system(command);
if status
    msg = sprintf('Compilation failed for model "%s" ',file_name);
    display_msg(msg, MsgType.ERROR, 'lustret_test_mutation', '');
    display_msg(msg, MsgType.DEBUG, 'lustret_test_mutation', '');
    display_msg(make_out, MsgType.DEBUG, 'lustret_test_mutation', '');
    err = 1;
    return
end

end

%% node inputs outputs
function main_node_struct = extract_main_node_struct(lus_file_path, main_node_name, LUSTREC, LUCTREC_INCLUDE_DIR)
main_node_struct = struct();
[lus_dir, lus_fname, ~] = fileparts(lus_file_path);
output_dir = fullfile(lus_dir, 'emf', strcat('tmp_',lus_fname));
if ~exist(output_dir, 'dir'); mkdir(output_dir); end
msg = sprintf('generating emf "%s"\n',lus_file_path);
display_msg(msg, MsgType.INFO, 'lustret_test_mutation', '');
command = sprintf('%s -I "%s" -d "%s" -emf  "%s"',...
    LUSTREC,LUCTREC_INCLUDE_DIR, output_dir, lus_file_path);
msg = sprintf('EMF_LUSTREC_COMMAND : %s\n',command);
display_msg(msg, MsgType.INFO, 'lustret_test_mutation', '');
[status, emf_out] = system(command);
if status==0
    contract_path = fullfile(output_dir,strcat(lus_fname, '.emf'));
    
    % extract main node struct from EMF
    data = BUtils.read_EMF(contract_path);
    nodes = data.nodes;
    nodes_names = fieldnames(nodes)';
    idx_main_node = find(ismember(nodes_names, main_node_name));
    if isempty(idx_main_node)
        display_msg(['Node ' main_node_name ' does not exist in EMF ' contract_path], MsgType.ERROR, 'Validation', '');
        return;
    end
    main_node_struct = nodes.(nodes_names{idx_main_node});
else
    msg = sprintf('generation of emf failed for file "%s" ',lus_fname);
    display_msg(msg, MsgType.ERROR, 'lustret_test_mutation', '');
    display_msg(msg, MsgType.DEBUG, 'lustret_test_mutation', '');
%     display_msg(emf_out, MsgType.DEBUG, 'lustret_test_mutation', '');
    
end



end

%% verification file
function verif_lus_path = create_mutant_verif_file(lus_file_path, mutant_lus_file_path, node_struct, node_name, new_node_name)
%% create verification file
[file_parent, mutant_lus_file_name, ~] = fileparts(mutant_lus_file_path);

filetext1 = BUtils.adapt_lustre_text(fileread(lus_file_path));
sep_line = '--******************** second file ********************';
filetext2 = BUtils.adapt_lustre_text(fileread(mutant_lus_file_path));
verif_line = '--******************** sVerification node ********************';
verif_node = BUtils.construct_verif_node(node_struct, node_name, new_node_name);

verif_lus_text = sprintf('%s\n%s\n%s\n%s\n%s', filetext1, sep_line, filetext2, verif_line, verif_node);

output_dir = fullfile(file_parent, strcat(mutant_lus_file_name, '_build'));
if ~exist(output_dir, 'dir'); mkdir(output_dir); end
verif_lus_path = fullfile(output_dir, strcat(mutant_lus_file_name, '_verif.lus'));
fid = fopen(verif_lus_path, 'w');
fprintf(fid, verif_lus_text);
fclose(fid);
end

%% create random vector test
function [input_struct, lustre_input_values] = get_random_test(inports, nb_steps,IMAX, IMIN)
numberOfInports = numel(inports);
input_struct.time = (0:1:nb_steps)';
input_struct.signals = [];
for i=1:numberOfInports
    input_struct.signals(i).name = inports(i).name;
    dim = 1;
    if strcmp(inports(i).datatype,'bool')
        input_struct.signals(i).values = LusValidateUtils.construct_random_booleans(nb_steps, IMIN, IMAX, dim);
        input_struct.signals(i).dimensions = dim;
    elseif strcmp(inports(i).datatype,'int')
        input_struct.signals(i).values = LusValidateUtils.construct_random_integers(nb_steps, IMIN, IMAX, inports(i).DataType, dim);
        input_struct.signals(i).dimensions = dim;
    else
        input_struct.signals(i).values = LusValidateUtils.construct_random_doubles(nb_steps, IMIN, IMAX,dim);
        input_struct.signals(i).dimensions = dim;
    end
end
number_of_inputs = nb_steps*numberOfInports;
%% Translate input_stract to lustre format (inline the inputs)
if numberOfInports>=1
    lustre_input_values = ones(number_of_inputs,1);
    index = 0;
    for i=0:nb_steps-1
        for j=1:numberOfInports
            dim = input_struct.signals(j).dimensions;
            if numel(dim)==1
                index2 = index + dim;
                lustre_input_values(index+1:index2) = input_struct.signals(j).values(i+1,:)';
            else
                index2 = index + (dim(1) * dim(2));
                signal_values = [];
                y = input_struct.signals(j).values(:,:,i+1);
                for idr=1:dim(1)
                    signal_values = [signal_values; y(idr,:)'];
                end
                lustre_input_values(index+1:index2) = signal_values;
            end
            
            index = index2;
        end
    end
    
else
    lustre_input_values = ones(1*nb_steps,1);
end
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
%% run Zustre or kind2 on verification file
function run_verif(verif_lus_path, Verif_dir, Backend)
timeout = '600';
cd(Verif_dir);
tools_config;
if strcmp(Backend, 'Z')
    command = sprintf('%s "%s" --node %s --xml  --matlab --timeout %s --save ',...
        ZUSTRE, verif_lus_path, 'top_verif', timeout);
    display_msg(['ZUSTRE_COMMAND ' command], MsgType.DEBUG, 'lustret_mutation_generation', '');
    
elseif strcmp(Backend, 'K')
    command = sprintf('%s --z3_bin %s -xml --timeout %s --lus_main %s "%s"',...
        KIND2, Z3, timeout, 'top_verif', verif_lus_path);
    display_msg(['KIND2_COMMAND ' command], MsgType.DEBUG, 'lustret_mutation_generation', '');
    
end
[status, solver_out] = system(command);
display_msg(solver_out, MsgType.RESULT, 'lustret_mutation_generation', '');
end