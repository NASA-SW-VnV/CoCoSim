function link_block_with_its_cocospec( cocospec_bloc_path, input_block_name, simulink_block_name, parent_block_name, index, isBaseName)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    DstBlkH = get_param(cocospec_bloc_path, 'PortHandles');
    inport_or_outport = get_param(input_block_name,'BlockType');
    Port_number = get_param(input_block_name,'Port');
    if strcmp(inport_or_outport,'Inport')
        if isBaseName
            SrcBlkH = get_param(input_block_name,'PortHandles');
            inport_handle = SrcBlkH.Outport(1);
        else
            SrcBlkH = get_param(simulink_block_name,'PortHandles');
            inport_handle = SrcBlkH.Inport(str2num(Port_number));
        end
        l = get_param(inport_handle,'line');
        SrcPortHandle = get_param(l ,'SrcPortHandle');
        add_line(parent_block_name, SrcPortHandle, DstBlkH.Inport(index), 'autorouting', 'on');
    elseif strcmp(inport_or_outport,'Outport')
        if isBaseName
            SrcBlkH = get_param(input_block_name,'PortHandles');
            inport_handle = SrcBlkH.Inport(1);
            l = get_param(inport_handle,'line');
            SrcPortHandle = get_param(l ,'SrcPortHandle');
        else
            SrcBlkH = get_param(simulink_block_name,'PortHandles');
            SrcPortHandle = SrcBlkH.Outport(str2num(Port_number));
        end
        add_line(parent_block_name, SrcPortHandle, DstBlkH.Inport(index), 'autorouting', 'on');
    end
end

