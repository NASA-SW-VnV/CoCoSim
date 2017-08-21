function [valid,lustrec_failed, ...
    lustrec_binary_failed, sim_failed] ...
    = compare_slx_lus_V2(model_full_path, lus_file_path, node_struct, node_name, output_dir, Backend )




%% define configuration variables
% cocosim_config;
config;
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
    generated_lus_file_path = cocoSim(model_full_path);
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
filetext1 = adapt_text(fileread(lus_file_path));
sep_line = '--******************** second file ********************';
filetext2 = adapt_text(fileread(generated_lus_file_path));
verif_line = '--******************** sVerification node ********************';
verif_node = construct_verif_node(node_struct, node_name, new_node_name);

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
    if strfind(solver_out,'<Answer>SAFE</Answer>') || strfind(solver_out,'>valid</Answer>')
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


%%
function t = adapt_text(t)
t = regexprep(t, '''', '''''');
t = regexprep(t, '%', '%%');
t = regexprep(t, '\\', '\\\');
end


%%
function verif_node = construct_verif_node(node_struct, node_name, new_node_name)
%inputs
node_inputs = node_struct.inputs;
nb_in = numel(node_inputs);
inputs_with_type = cell(nb_in,1);
inputs = cell(nb_in,1);
for i=1:nb_in
    dt = LusValidateUtils.get_lustre_dt(node_inputs(i).datatype);
    inputs_with_type{i} = sprintf('%s: %s',node_inputs(i).name, dt);
    inputs{i} = node_inputs(i).name;
end
inputs_with_type = strjoin(inputs_with_type, ';');
inputs = strjoin(inputs, ',');

%outputs
node_outputs = node_struct.outputs;
nb_out = numel(node_outputs);
vars_type = cell(nb_out,1);
outputs_1 = cell(nb_out,1);
outputs_2 = cell(nb_out,1);

for i=1:nb_out
    dt = LusValidateUtils.get_lustre_dt(node_outputs(i).datatype);
    vars_type{i} = sprintf('%s_1, %s_2: %s;',node_outputs(i).name, ...
        node_outputs(i).name, dt);
    outputs_1{i} = strcat(node_outputs(i).name, '_1');
    outputs_2{i} = strcat(node_outputs(i).name, '_2');
    ok_exp{i} = sprintf('%s = %s',outputs_1{i}, outputs_2{i});
end
vars_type = strjoin(vars_type, '\n');
outputs_1 = ['(' strjoin(outputs_1, ',') ')'];
outputs_2 = ['(' strjoin(outputs_2, ',') ')'];
ok_exp = strjoin(ok_exp, ' and ');

outputs = 'OK:bool';
header_format = 'node top_verif(%s)\nreturns(%s);\nvar %s\nlet\n';
header = sprintf(header_format,inputs_with_type, outputs, vars_type);

functions_call_fmt =  '%s = %s(%s);\n%s = %s(%s);\n';
functions_call = sprintf(functions_call_fmt, outputs_1, node_name, inputs, outputs_2, new_node_name, inputs);

Ok_def = sprintf('OK = %s;\n', ok_exp);

Prop = '--%%PROPERTY  OK=true;';

verif_node = sprintf('%s\n%s\n%s\n%s\ntel', header, functions_call, Ok_def, Prop);

end