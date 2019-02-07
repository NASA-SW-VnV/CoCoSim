%% construct EMF  model
function [status, new_name_path, emf_path, xml_trace] = construct_EMF_model(...
        lus_file_path, node_name, output_dir, organize_blocks)
    tools_config;
    new_name_path = '';
    xml_trace = [];
    status = BUtils.check_files_exist(LUSTREC, LUCTREC_INCLUDE_DIR);
    if status
        return;
    end
    if ~exist('organize_blocks', 'var')
        organize_blocks = 0;
    end
    %1- Generate Simulink model from original Lustre file using EMF
    %backend.

    %generate emf json
    [emf_path, status] = ...
        LustrecUtils.generate_emf(lus_file_path, output_dir, ...
        LUSTREC, LUSTREC_OPTS, LUCTREC_INCLUDE_DIR);
    if status
        return;
    end

    [~, lus_fname, ~] = fileparts(lus_file_path);
    %generate simulink model
    if ~strcmp(MatlabUtils.fileBase(lus_fname), node_name)
        new_model_name = BUtils.adapt_block_name(strcat(lus_fname,'_',node_name));
    else
        new_model_name = BUtils.adapt_block_name(strcat(lus_fname,'_EMF'));
    end
    clear lus2slx
    [status, new_name_path, xml_trace] = lus2slx(emf_path, output_dir, new_model_name, node_name, organize_blocks, 1);
    if status
        return;
    end

    %2- Create Simulink model containing both SLX1 and SLX2
    load_system(new_name_path);

    main_block_path = strcat(new_model_name,'/', BUtils.adapt_block_name(node_name));
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
    configSet = getActiveConfigSet(new_model_name);
    set_param(configSet, 'Solver', 'FixedStepDiscrete', 'FixedStep', '1');
    save_system(new_model_name,'','OverwriteIfChangedOnDisk',true);

end
