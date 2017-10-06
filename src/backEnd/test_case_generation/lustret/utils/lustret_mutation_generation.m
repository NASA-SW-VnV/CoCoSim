function [ err, output_dir] = lustret_mutation_generation( lus_full_path )
%LUSTRET_TEST_GENERATION Generate test cases based on mutation.

err = 0;
generation_start = tic;

[file_parent, file_name, ~] = fileparts(lus_full_path);
output_dir = fullfile(file_parent, strcat(file_name,'_mutants'));
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
else
    mutant_path = fullfile(output_dir, strcat(file_name, '.mutant.n1.lus'));
    if BUtils.isLastModified(lus_full_path, mutant_path)
        err = 0;
        display_msg(['mutants have been already generated'], MsgType.DEBUG, 'Validation', '');
        return;
    end
end

tools_config;
if ~exist('LUSTRET','var')
    display_msg('Lustret compiler is not declared in cocosim_config file', MsgType.ERROR, 'lustret_mutation_generation', '');
    err = 1;
    return;
end
if ~exist('LUCTREC_INCLUDE_DIR','var')
    display_msg('LUCTREC_INCLUDE_DIR variable is not declared in cocosim_config file', MsgType.ERROR, 'lustret_mutation_generation', '');
    err = 1;
    return;
end

command = sprintf('%s -I "%s" -node %s -d "%s" "%s"',LUSTRET, LUCTREC_INCLUDE_DIR, file_name, output_dir, lus_full_path);
msg = sprintf('LUSTRET_COMMAND : %s\n',command);
display_msg(msg, MsgType.INFO, 'lustret_mutation_generation', '');

[status, lustret_out] = system(command);
if status
    msg = sprintf('lustrec failed for model "%s"',file_name);
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

