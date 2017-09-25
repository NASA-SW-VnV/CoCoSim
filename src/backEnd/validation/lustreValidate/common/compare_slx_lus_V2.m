function [valid,lustrec_failed, ...
    lustrec_binary_failed, sim_failed] ...
    = compare_slx_lus_V2(model_full_path, lus_file_path, node_struct, node_name, output_dir, Backend )




%% define configuration variables
cocosim_config;
% config;
assignin('base', 'SOLVER', 'V');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);
OldPwd = pwd;

%% define default outputs
lustrec_failed=0;
lustrec_binary_failed=0;
sim_failed=0;
valid = 0;
%%
[model_path, slx_file_name, ~] = fileparts(char(model_full_path));
[~, lus_file_name, ~] = fileparts(char(lus_file_path));
addpath(model_path);

%% generate lustre code
try
    f_msg = sprintf('Compiling model "%s" to Lustre\n',slx_file_name);
    display_msg(f_msg, MsgType.RESULT, 'compare_slx_lus_V2', '');
    GUIUtils.update_status('Runing CocoSim');
    evalin('base','nodisplay = 1;');
    generated_lus_file_path = lustre_compiler(model_full_path);
    [~, new_node_name, ~] = fileparts(generated_lus_file_path);
    bdclose('all');
catch ME
    msg = sprintf('Translation Failed for model "%s" :\n%s\n%s',...
        slx_file_name,ME.identifier,ME.message);
    display_msg(msg, MsgType.ERROR, 'validation', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
    rethrow(ME);
end

%% create verification file
filetext1 = BUtils.adapt_lustre_text(fileread(lus_file_path));
sep_line = '--******************** second file ********************';
filetext2 = BUtils.adapt_lustre_text(fileread(generated_lus_file_path));
verif_line = '--******************** sVerification node ********************';
verif_node = BUtils.construct_verif_node(node_struct, node_name, new_node_name);

verif_lus_text = sprintf('%s\n%s\n%s\n%s\n%s', filetext1, sep_line, filetext2, verif_line, verif_node);

verif_lus_path = fullfile(output_dir, strcat(lus_file_name, '_verif.lus'));
fid = fopen(verif_lus_path, 'w');
fprintf(fid, verif_lus_text);
fclose(fid);

%%
timeout = '600';
if strcmp(Backend, 'Z')
    command = sprintf('%s "%s" --node %s --xml  --matlab --timeout %s --save ',...
        ZUSTRE, verif_lus_path, 'top_verif', timeout);
     display_msg(['ZUSTRE_COMMAND ' command], MsgType.DEBUG, 'compare_slx_lus_V2', '');
        
elseif strcmp(Backend, 'K')
    command = sprintf('%s --z3_bin %s -xml --timeout %s --lus_main %s "%s"',...
        KIND2, Z3, timeout, 'top_verif', verif_lus_path);
    display_msg(['KIND2_COMMAND ' command], MsgType.DEBUG, 'compare_slx_lus_V2', '');
end
[status, solver_out] = system(command);
display_msg(solver_out, MsgType.RESULT, 'compare_slx_lus_V2', '');
if status == 0
    if ~isempty(strfind(solver_out,'<Answer>SAFE</Answer>')) || ~isempty(strfind(solver_out,'>valid</Answer>'))
        valid = 1;
    else
        valid=0;
    end
else
    valid = 0;
end
%% report
f_msg = '';
f_msg = [f_msg 'Verification lustre file ' verif_lus_path '\n'];
display_msg(f_msg, MsgType.RESULT, 'validation', '');


cd(OldPwd)


end
