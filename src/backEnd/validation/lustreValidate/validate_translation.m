function [valid, validation_compute,lustrec_failed, ...
    lustrec_binary_failed, sim_failed, lus_file_path] = validate_translation(model_full_path, show_model, deep_CEX, min_max_constraints)


validation_start = tic;


%close all simulink models
bdclose('all')
%% define parameters if not given by the user
if nargin < 3
    show_model = 0;
elseif show_model
    open(model_full_path);
end
if ~exist('min_max_constraints', 'var')
    min_max_constraints = [];
end

if ~exist('deep_CEX', 'var')
    deep_CEX = 0;
end
assignin('base', 'SOLVER', 'V');
assignin('base', 'RUST_GEN', 0);
assignin('base', 'C_GEN', 0);

[model_path, file_name, ext] = fileparts(char(model_full_path));
addpath(model_path);
%% generate lustre code
try
    f_msg = sprintf('Compiling model "%s" to Lustre\n',file_name);
    display_msg(f_msg, MsgType.RESULT, 'validation', '');
    GUIUtils.update_status('Runing CocoSim');
    lus_file_path = cocoSim(model_full_path);
    [output_dir, lus_file_name, ~] = fileparts(lus_file_path);
    file_name = lus_file_name;
    main_node = lus_file_name;
    model_full_path = fullfile(model_path,strcat(file_name,ext));
    if show_model
        open(model_full_path);
    end
    
catch ME
    msg = sprintf('Translation Failed for model "%s" :\n%s\n%s',...
        file_name,ME.identifier,ME.message);
    display_msg(msg, MsgType.ERROR, 'validation', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
    rethrow(ME);
end

%% for data types
BUtils.force_inports_DT(file_name);
%% launch validation

try
    [valid, lustrec_failed, lustrec_binary_failed, sim_failed] = compare_slx_lus(model_full_path, lus_file_path, main_node, output_dir, show_model, min_max_constraints);
catch ME
    display_msg(ME.message, MsgType.ERROR, 'validation', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
    rethrow(ME);
end


if ~lustrec_failed && ~sim_failed && ~lustrec_binary_failed && ~valid && (deep_CEX > 0)
    %get tracability
    trace_file_name = fullfile(output_dir,strcat(file_name,'.cocosim.trace.xml'));
    DOMNODE = xmlread(trace_file_name);
    xRoot = DOMNODE.getDocumentElement;
    xml_nodes = xRoot.getElementsByTagName('Node');
    validate_components(model_full_path, file_name, file_name, lus_file_path, xml_nodes, output_dir, deep_CEX);
end


% close_system(model_full_path,0);
% bdclose('all')

if sim_failed==1
    validation_compute = -1;
else
    validation_compute = toc(validation_start);
end
end

function validate_components(file_path,file_name,block_path,  lus_file_path, xml_nodes, output_dir, deep_CEX, deep_current)
ss = find_system(block_path, 'SearchDepth',1, 'BlockType','SubSystem');
if ~exist('deep_current', 'var')
    deep_current = 1;
end
for i=1:numel(ss)
    if strcmp(ss{i}, block_path)
        continue;
    end
    display_msg(['Validating SubSystem ' ss{i}], MsgType.INFO, 'validation', '');
    node_name = get_lustre_node_from_Simulink_block_name(xml_nodes,ss{i});
    if ~strcmp(node_name, '')
        [new_model_path, ~] = extract_subsys(file_name, ss{i}, output_dir );
        try
            [valid, ~, ~, ~] = compare_slx_lus(new_model_path, lus_file_path, node_name, output_dir);
            if ~valid
                 display_msg(['SubSystem ' ss{i} ' is not valid (see Counter example above)'], MsgType.RESULT, 'validation', '');
                 load_system(file_path);
                 validate_components(file_path, file_name, ss{i}, lus_file_path, xml_nodes, output_dir, deep_CEX, deep_current+1);
                 if deep_current > deep_CEX; return;end
            else
                 display_msg(['SubSystem ' ss{i} ' is valid'], MsgType.RESULT, 'validation', '');
            end
        catch ME
            display_msg(ME.message, MsgType.ERROR, 'validation', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
            rethrow(ME);
        end
    else
        display_msg(['No node for subsytem ' ss{i} ' is found'], MsgType.INFO, 'validation', '');
    end
end

end
function [new_model_path, new_model_name] = extract_subsys(file_name, block_name, output_dir )
block_name_adapted = BUtils.adapt_block_name(SLXUtils.naming(LusValidateUtils.name_format(block_name)));
new_model_name = strcat(file_name,'_', block_name_adapted);
new_model_name = BUtils.adapt_block_name(new_model_name);
new_model_path = fullfile(output_dir, strcat(new_model_name,'.slx'));
if exist(new_model_path,'file')
    if bdIsLoaded(new_model_name)
        close_system(new_model_name,0)
    end
    delete(new_model_path);
end
close_system(new_model_name,0);
model_handle = new_system(new_model_name);

Simulink.SubSystem.copyContentsToBlockDiagram(block_name, model_handle)

%% Save system
save_system(model_handle,new_model_path,'OverwriteIfChangedOnDisk',true);
close_system(file_name,0);
end

%%
function node_name = get_lustre_node_from_Simulink_block_name(xml_nodes,Simulink_block_name)
node_name = '';
for idx_node=0:xml_nodes.getLength-1
    block_name = xml_nodes.item(idx_node).getAttribute('block_name');
    if strcmp(block_name, Simulink_block_name)
        node_name = char(xml_nodes.item(idx_node).getAttribute('node_name'));
        break;
    end
    
end
end