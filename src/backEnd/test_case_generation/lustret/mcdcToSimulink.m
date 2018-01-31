%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ new_model_path ] = mcdcToSimulink( model_path, contract_path, cocosim_trace_file )
%MCDCTOSIMULINK try to bring back the MC-DC conditions to simulink level.

[coco_dir, ~, ~] = fileparts(contract_path);
[model_dir, base_name, ~] = fileparts(model_path);
if ~exist('cocosim_trace_file', 'var')
    cocosim_trace_file = fullfile(coco_dir,strcat(base_name,'.cocosim.trace.xml'));
end

try
    save_system(model_path)
    bdclose('all')
    new_model_path = '';
    
    % read the emf contract
    data = BUtils.read_json(contract_path);
    
    % we add a Postfix to differentiate it with the original Simulink model
    new_model_name = strcat(base_name,'_with_mcdc');
    new_name = fullfile(model_dir,strcat(new_model_name,'.slx'));
    
    display_msg(['MCDC model path: ' new_name ], MsgType.INFO, 'generate_invariants_Zustre', '');
    
    if exist(new_name,'file')
        if bdIsLoaded(new_model_name)
            close_system(new_model_name,0)
        end
        delete(new_name);
    end
    
    %we load the original model
    load_system(model_path);
    %we save it as the output model
    close_system(new_name,0)
    save_system(model_path,new_name, 'OverwriteIfChangedOnDisk', true);
    load_system(new_name);
    
    %get tracability
    
    DOMNODE = xmlread(cocosim_trace_file);
    xRoot = DOMNODE.getDocumentElement;
    nb_mcdc = 0;
    
    
    [status, translated_nodes_path, ~]  = mcdc2slx(contract_path, coco_dir, [], [], 1);
    if status
        display_msg('Translation failed for MC-DC conditions',...
            MsgType.INFO, 'generate_invariants_Zustre', '');
        return;
    end
    [~, translated_nodes, ~] = fileparts(translated_nodes_path);
    load_system(translated_nodes);
    
    nodes = data.nodes;
    for node = fieldnames(nodes)'
        original_name = nodes.(node{1}).original_name;
        simulink_block_name = XMLUtils.get_Simulink_block_from_lustre_node_name(xRoot, ...
            original_name, base_name, new_model_name);
        if strcmp(simulink_block_name, '')
            continue;
        elseif strcmp(simulink_block_name,base_name)
            isBaseName = true;
            simulink_block_name = strcat(new_model_name,'/',base_name);
        else
            try
                maskType =  get_param(simulink_block_name,'MaskType');
                if strcmp(maskType, 'Observer')
                    continue;
                end
            catch ME
                display_msg(ME.getReport(), MsgType.DEBUG, 'generate_invariants_Zustre', '');
                continue;
            end
            isBaseName = false;
        end
        parent_block_name = fileparts(simulink_block_name);
        %for having a good order of blocks
        try
            if isBaseName
                position  = BUtils.get_obs_position(new_model_name);
            else
                position  = get_param(simulink_block_name,'Position');
            end
        catch ME
            msg = sprintf('There is no block called %s in your model\n', simulink_block_name);
            msg1 = [msg, sprintf('if the block %s exists, make sure it is atomic', simulink_block_name)];
            msg2 = sprintf('%s\n%s\n', msg1, ME.getReport());
            warndlg(msg1,'CoCoSim: Warning');
            fprintf(msg2);
            continue;
        end
        x = position(1);
        y = position(2)+250;
        
        %Adding the cocospec subsystem related with the Simulink subsystem
        %"simulink_block_name"
        cocospec_block_path = strcat(simulink_block_name,'_cocospec');
        n = 1;
        while getSimulinkBlockHandle(cocospec_block_path) ~= -1
            cocospec_block_path = strcat(cocospec_block_path, num2str(n));
            n = n + 1;
            y = y+250;
        end
        node_subsystem = strcat(translated_nodes, '/', BUtils.adapt_block_name(node{1}));
        add_block(node_subsystem,...
            cocospec_block_path,...
            'Position',[(x+100) y (x+250) (y+50)]);
        set_mask_parameters(cocospec_block_path);
        nb_mcdc = nb_mcdc + 1;
        
        %we plot the invariant of the block
        scope_block_path = strcat(simulink_block_name,'_scope',num2str(n));
        add_block('simulink/Commonly Used Blocks/Scope',...
            scope_block_path,...
            'Position',[(x+300) y (x+350) (y+50)]);
        
        %we link the Scope with cocospec block
        SrcBlkH = get_param(strcat(cocospec_block_path),'PortHandles');
        DstBlkH = get_param(scope_block_path, 'PortHandles');
        add_line(parent_block_name, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
        
        blk_inputs = nodes.(node{1}).inputs;
        %link inputs to the subsystem.
        for index=1:numel(blk_inputs)
            var_name = BUtils.adapt_block_name(blk_inputs(index).original_name);
            input_block_name = get_input_block_name_from_variable(xRoot, original_name, var_name, base_name,new_model_name);
            link_block_with_its_cocospec(cocospec_block_path,  input_block_name, simulink_block_name, parent_block_name, index, isBaseName);
        end
    end
    
    if nb_mcdc == 0
        warndlg('No cocospec contracts were generated','CoCoSim: Warning');
        return;
    end
    save_system(new_name);
    new_model_path = new_name;
    open(new_name);
    save_system(new_name,[],'OverwriteIfChangedOnDisk',true);
    close_system(translated_nodes,0)
    
catch ME
    display_msg(ME.message, MsgType.ERROR, 'mcdcToSimulink', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'mcdcToSimulink', '');
    rethrow(ME);
end
end

