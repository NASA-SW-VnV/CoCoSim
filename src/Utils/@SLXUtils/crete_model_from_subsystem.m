
function [new_model_path, new_model_name, status] = ...
    crete_model_from_subsystem(file_name, ss_path, output_dir )
    block_name_adapted = ...
        BUtils.adapt_block_name(MatlabUtils.naming(LusValidateUtils.name_format(ss_path)));
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
    blk_name = get_param(ss_path, 'Name');
    new_blkH = add_block(ss_path, ...
        strcat(new_model_name, '/', blk_name));
    newBlokPortHandles = get_param(new_blkH, 'PortHandles');
    %Inports
    status = 0;
    for i=1:numel(newBlokPortHandles.Enable)
        status = status + addInport(newBlokPortHandles.Enable(i));
    end
    for i=1:numel(newBlokPortHandles.Ifaction)
        status = status + addInport(newBlokPortHandles.Ifaction(i));
    end
    for i=1:numel(newBlokPortHandles.Inport)
        status = status + addInport(newBlokPortHandles.Inport(i));
    end
    for i=1:numel(newBlokPortHandles.Reset)
        status = status + addInport(newBlokPortHandles.Reset(i));
    end
    for i=1:numel(newBlokPortHandles.Trigger)
        status = status + addInport(newBlokPortHandles.Trigger(i));
    end
    %Outport
    for i=1:numel(newBlokPortHandles.Outport)
        status = status + addOutport(newBlokPortHandles.Outport(i));
    end
    try
        BlocksPosition_pp(new_model_path, 1);
    catch
    end
    %% Save system
    save_system(model_handle,new_model_path,'OverwriteIfChangedOnDisk',true);
        function status = addInport(newBlkPort)
            try
                status = 0;
                inport_name = fullfile(new_model_name, 'In1');
                inport_handle = add_block('simulink/Ports & Subsystems/In1',...
                    inport_name,...
                    'MakeNameUnique', 'on');
                inportPortHandles = get_param(inport_handle, 'PortHandles');
                add_line(new_model_name,...
                    inportPortHandles.Outport(1), newBlkPort,...
                    'autorouting', 'on');
            catch Me
                display_msg(Me.getReport(), ...
                    MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
                status = 1;
            end
        end
        function status = addOutport(newBlkPort)
            try
                status = 0;
                outport_name = fullfile(new_model_name, 'Out1');
                outport_handle = add_block('simulink/Ports & Subsystems/Out1',...
                    outport_name,...
                    'MakeNameUnique', 'on');
                outportPortHandles = get_param(outport_handle, 'PortHandles');
                add_line(new_model_name,...
                    newBlkPort, outportPortHandles.Inport(1),...
                    'autorouting', 'on');
            catch Me
                display_msg(Me.getReport(), ...
                    MsgType.DEBUG, 'SLXUtils.createSubsystemFromBlk', '');
                status = 1;
            end
        end

end

