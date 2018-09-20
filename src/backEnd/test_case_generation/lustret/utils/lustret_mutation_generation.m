function [ err, output_dir] = lustret_mutation_generation( lus_full_path, nb_mutants_max )
%LUSTRET_TEST_GENERATION Generate test cases based on mutation.

if ~exist('nb_mutants_max', 'var')
    nb_mutants_max = 500;
end

err = 0;
generation_start = tic;
[file_parent, file_name, ~] = fileparts(lus_full_path);
output_dir = fullfile(file_parent, strcat(file_name,'_mutants'));
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
else
    mutant_path = fullfile(...
        output_dir, ...
        strcat(file_name, '.mutant.n',num2str(nb_mutants_max),'.lus'));
    if BUtils.isLastModified(lus_full_path, mutant_path)
        err = 0;
        display_msg('mutants have been already generated', MsgType.DEBUG, 'Validation', '');
        return;
    end
end

tools_config;
status = BUtils.check_files_exist(LUSTRET, LUCTREC_INCLUDE_DIR);
if status
    msg = 'LUSTREC not found, please configure tools_config file under tools folder';
    display_msg(msg, MsgType.ERROR, 'lustret_mutation_generation', '');
    err = 1;
    return;
end



command = sprintf('%s -I %s -nb-mutants %d -node %s -d %s %s',LUSTRET, LUCTREC_INCLUDE_DIR, nb_mutants_max, file_name, output_dir, lus_full_path);
msg = sprintf('LUSTRET_COMMAND : %s\n',command);
display_msg(msg, MsgType.INFO, 'lustret_mutation_generation', '');
display_msg('Please Kill me (Ctrl+C) if I am taking long time',...
    MsgType.INFO, 'lustret_mutation_generation', '');
[status, lustret_out, ~] = system_timeout(command,7);
if status
    msg = sprintf('lustret failed for model "%s"',file_name);
    display_msg(msg, MsgType.INFO, 'lustret_mutation_generation', '');
    display_msg(msg, MsgType.ERROR, 'lustret_mutation_generation', '');
    display_msg(msg, MsgType.DEBUG, 'lustret_mutation_generation', '');
    display_msg(lustret_out, MsgType.DEBUG, 'lustret_mutation_generation', '');
    err = 1;
    return
end


generation_stop = toc(generation_start);
fprintf('mutations has been generated in %f seconds\n', generation_stop);
end

