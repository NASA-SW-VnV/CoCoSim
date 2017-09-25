function [valid, lustrec_failed, lustrec_binary_failed, sim_failed] = validate_lus2slx_V2( lus_file_path, main_node_name, Backend)
%VALIDATE_LUS2SLX_V2 validate the translation using equivalent model
%checking
[lus_dir, lus_fname, ~] = fileparts(lus_file_path);
if nargin < 2 || isempty(main_node_name)
    main_node_name = lus_fname;
end
if nargin < 3
    Backend = 'Z';
end
OldPwd = pwd;
cocosim_config;
% config;
%% output initialisation
valid = -1;
lustrec_failed = -1;
lustrec_binary_failed = -1;
sim_failed = -1;
%% generate EMF

output_dir = fullfile(lus_dir, 'tmp', strcat('tmp_',lus_fname));
if ~exist(output_dir, 'dir'); mkdir(output_dir); end
msg = sprintf('generating emf "%s"\n',lus_file_path);
display_msg(msg, MsgType.INFO, 'validation', '');
command = sprintf('%s -I "%s" -d "%s" -emf  "%s"',...
    LUSTREC,LUCTREC_INCLUDE_DIR, output_dir, lus_file_path);
msg = sprintf('EMF_LUSTREC_COMMAND : %s\n',command);
display_msg(msg, MsgType.INFO, 'validation', '');
[status, emf_out] = system(command);
if status
    err = sprintf('generation of emf failed for file "%s" ',lus_fname);
    display_msg(err, MsgType.ERROR, 'validation', '');
    display_msg(err, MsgType.DEBUG, 'validation', '');
    display_msg(emf_out, MsgType.DEBUG, 'validation', '');
    cd(OldPwd);
    return
end

contract_path = fullfile(output_dir,strcat(lus_fname, '.emf'));

%% extract SLX for all nodes
try
    display_msg('Runing LUS2SLX', MsgType.INFO, 'validation', '');
    translated_nodes_path  = lus2slx(contract_path, output_dir);
catch ME
    display_msg(ME.message, MsgType.ERROR, 'validation', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
    cd(OldPwd);
    return;
end

[~, translated_nodes, ~] = fileparts(translated_nodes_path);
load_system(translated_nodes);

%% extract main node struct from EMF
data = BUtils.read_EMF(contract_path);
nodes = data.nodes;
nodes_names = fieldnames(nodes)';
idx_main_node = find(ismember(nodes_names,main_node_name));
if isempty(idx_main_node)
    display_msg(['Node ' main_node_name ' does not exist in EMF ' contract_path], MsgType.ERROR, 'Validation', '');
    return;
end
main_node_struct = nodes.(nodes_names{idx_main_node});

%% extract the main node Subsystem
base_name = regexp(lus_fname,'\.','split');
new_model_name = strcat(base_name{1},'_', main_node_name);
new_name = fullfile(output_dir, strcat(new_model_name,'.slx'));
if exist(new_name,'file')
    if bdIsLoaded(new_model_name)
        close_system(new_model_name,0)
    end
    delete(new_name);
end
close_system(new_model_name,0);
model_handle = new_system(new_model_name);


main_block_path = strcat(new_model_name,'/', main_node_name);
node_subsystem = strcat(translated_nodes, '/', main_node_name);
add_block(node_subsystem,...
    main_block_path);
portHandles = get_param(main_block_path, 'PortHandles');
nb_inports = numel(portHandles.Inport);
nb_outports = numel(portHandles.Outport);
m = max(nb_inports, nb_outports);
set_param(main_block_path,'Position',[100 0 (100+250) (0+50*m)]);

for i=1:nb_inports
    p = get_param(portHandles.Inport(i), 'Position');
    x = p(1) - 50;
    y = p(2);
    inport_name = strcat(new_model_name,'/',main_node_struct.inputs(i).name);
    add_block('simulink/Ports & Subsystems/In1',...
        inport_name,...
        'Position',[(x-10) (y-10) (x+10) (y+10)]);
    SrcBlkH = get_param(inport_name,'PortHandles');
    add_line(new_model_name, SrcBlkH.Outport(1), portHandles.Inport(i), 'autorouting', 'on');
end

for i=1:nb_outports
    p = get_param(portHandles.Outport(i), 'Position');
    x = p(1) + 50;
    y = p(2);
    outport_name = strcat(new_model_name,'/',main_node_struct.outputs(i).name);
    add_block('simulink/Ports & Subsystems/Out1',...
        outport_name,...
        'Position',[(x-10) (y-10) (x+10) (y+10)]);
    DstBlkH = get_param(outport_name,'PortHandles');
    add_line(new_model_name, portHandles.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
end
%% Save system
configSet = getActiveConfigSet(model_handle);
set_param(configSet, 'Solver', 'FixedStepDiscrete');
save_system(model_handle,new_name,'OverwriteIfChangedOnDisk',true);
% open(new_name)


%% launch validation

if ~exist(output_dir, 'dir'); mkdir(output_dir); end
try
    [valid, lustrec_failed, lustrec_binary_failed, sim_failed] =...
        compare_slx_lus_V2(new_name, lus_file_path, main_node_struct, main_node_name, ...
        output_dir, Backend);
    if ~valid
        display_msg(['Node ' main_node_name ' is not valid (see Counter example above)'], MsgType.RESULT, 'validation', '');
    else
         display_msg(['Node ' main_node_name ' is valid :)'], MsgType.RESULT, 'validation', '');
    end
   
catch ME
    display_msg(ME.message, MsgType.ERROR, 'validation', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
    cd(OldPwd);
    return;
end


cd(OldPwd);
close_system(translated_nodes,0);
end
