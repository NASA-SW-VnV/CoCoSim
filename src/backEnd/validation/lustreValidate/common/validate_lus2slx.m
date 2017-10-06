function [valid, lustrec_failed, lustrec_binary_failed, sim_failed] = validate_lus2slx( lus_file_path, main_node, stop_at_first_cex)
%VALIDATE_LUS2SLX validate the translation lustre 2 simulink by generating
%random inputs
[~, lus_fname, ~] = fileparts(lus_file_path);
if nargin < 2 || isempty(main_node)
    main_node = BUtils.adapt_block_name(lus_fname);
end

if ~exist('stop_at_first_cex', 'var')
    stop_at_first_cex = 1;
end
OldPwd = pwd;
tools_config;
% config;


%%
valid = -1;
lustrec_failed = -1;
lustrec_binary_failed = -1;
sim_failed = -1;

%% generate EMF
[emf_path, status] = LustrecUtils.generate_emf(lus_file_path, LUSTREC, LUCTREC_INCLUDE_DIR);
if status
    return;
end
[output_dir, ~, ~] = fileparts(emf_path);
%% generate Lusi file
[lusi_path, status] = LustrecUtils.generate_lusi(lus_file_path, LUSTREC );
if status
    return;
end
%% extract SLX for all nodes
try
    translated_nodes_path  = lus2slx(emf_path, output_dir);
catch ME
    display_msg(ME.message, MsgType.ERROR, 'validation', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
    cd(OldPwd);
    return;
end

[~, translated_nodes, ~] = fileparts(translated_nodes_path);
load_system(translated_nodes);

data = BUtils.read_EMF(emf_path);
nodes = data.nodes;
emf_nodes_names = fieldnames(nodes)';
lusi_text = fileread(lusi_path);
nodes_names = {};
for node_idx =1:numel(emf_nodes_names) 
    name = emf_nodes_names{node_idx};
    pattern = strcat('(node|function)\s+',name,'\s*\(');
    tokens = regexp(lusi_text, pattern,'match');
    if ~isempty(tokens) && ~(endsWith(name, '_unless') || endsWith(name, '_handler_until'))
        nodes_names{numel(nodes_names) + 1} = name;
    end
end
for node_idx =0:numel(nodes_names) 
    if node_idx==0 
        if ismember(main_node, nodes_names)
            node_name = main_node;
        else
            continue;
        end
    else
        node_name = BUtils.adapt_block_name(nodes_names{node_idx});
        if strcmp(node_name, main_node)
            continue;
        end
    end
    %% extract the main node Subsystem
    base_name = regexp(lus_fname,'\.','split');
    new_model_name = BUtils.adapt_block_name(strcat(base_name{1},'_', node_name));
    new_name = fullfile(output_dir, strcat(new_model_name,'.slx'));
    if exist(new_name,'file')
        if bdIsLoaded(new_model_name)
            close_system(new_model_name,0)
        end
        delete(new_name);
    end
    close_system(new_model_name,0);
    model_handle = new_system(new_model_name);
    
    
    main_block_path = strcat(new_model_name,'/', node_name);
    node_subsystem = strcat(translated_nodes, '/', node_name);
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
        inport_name = strcat(new_model_name,'/In',num2str(i));
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
        outport_name = strcat(new_model_name,'/Out',num2str(i));
        add_block('simulink/Ports & Subsystems/Out1',...
            outport_name,...
            'Position',[(x-10) (y-10) (x+10) (y+10)]);
        DstBlkH = get_param(outport_name,'PortHandles');
        add_line(new_model_name, portHandles.Outport(i), DstBlkH.Inport(1), 'autorouting', 'on');
    end
    %% Save system
    configSet = getActiveConfigSet(model_handle);
    set_param(configSet, 'Solver', 'FixedStepDiscrete', 'FixedStep', '1');
    save_system(model_handle,new_name,'OverwriteIfChangedOnDisk',true);
    
    % open(new_name)
    
    %% launch validation
    
    if ~exist(output_dir, 'dir'); mkdir(output_dir); end
    try
        [valid, lustrec_failed, lustrec_binary_failed, sim_failed] =compare_slx_lus(new_name, lus_file_path, node_name, ...
            output_dir);
        if ~valid
                display_msg(['Node ' node_name ' is not valid (see Counter example above)'], MsgType.RESULT, 'validation', '');
                if stop_at_first_cex
                    break;
                end
        end
        if node_idx==0 && (valid || stop_at_first_cex)
            break;
        elseif node_idx>0 && ~lustrec_failed && ~sim_failed && ~lustrec_binary_failed && ~valid && stop_at_first_cex
            break;
        end
    catch ME
        display_msg(ME.message, MsgType.ERROR, 'validation', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'validation', '');
        cd(OldPwd);
        return;
    end
    
end
cd(OldPwd);
close_system(translated_nodes,0);

%% clean tmp files
system(['rm ' lusi_path]);


% if ~lustrec_failed && ~sim_failed && ~lustrec_binary_failed && ~valid && ~stop_at_first_cex
%     %get tracability
%     trace_file_name = fullfile(output_dir,strcat(lus_fname,'.emf.trace.xml'));
%     DOMNODE = xmlread(trace_file_name);
%     xRoot = DOMNODE.getDocumentElement;
%     xml_nodes = xRoot.getElementsByTagName('Node');
%     validate_components(new_name, new_model_name, new_model_name, lus_file_path, xml_nodes,base_name{1}, output_dir, stop_at_first_cex);
% end
end

function validate_components(file_path,file_name,block_path,  lus_file_path, xml_nodes,base_name, output_dir, stop_at_first_cex)
ss = find_system(block_path, 'SearchDepth',1, 'BlockType','SubSystem');
for i=1:numel(ss)
    if strcmp(ss{i}, block_path)
        continue;
    end
    display_msg(['Validating SubSystem ' ss{i}], MsgType.INFO, 'validation', '');
    origin_ss = regexprep(ss{i}, strcat('^',file_name,'/'), strcat(base_name,'_emf/'));
    node_name = get_lustre_node_from_Simulink_block_name(xml_nodes,origin_ss);
    if ~strcmp(node_name, '')
        [new_model_path, ~] = extract_subsys(file_name, ss{i}, output_dir );
        try
            [valid, ~, ~, ~] = compare_slx_lus(new_model_path, lus_file_path, node_name, output_dir);
            if ~valid
                display_msg(['SubSystem ' ss{i} ' is not valid (see Counter example above)'], MsgType.RESULT, 'validation', '');
                load_system(file_path);
                validate_components(file_path, file_name, ss{i}, lus_file_path, xml_nodes,base_name,  output_dir, stop_at_first_cex);
                if stop_at_first_cex; return;end
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
if getSimulinkBlockHandle(strcat(block_name, '/Reset'))>0
    add_block(block_name, ...
        strcat(new_model_name, '/tmp'));
    delete_block( strcat(new_model_name, '/tmp','/Reset'));
    Simulink.BlockDiagram.expandSubsystem( strcat(new_model_name, '/tmp'));
else
    Simulink.SubSystem.copyContentsToBlockDiagram(block_name, model_handle)
end
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
