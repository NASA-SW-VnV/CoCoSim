%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function inport_idx = add_demux(new_model_name, inport_idx, inport_name, dim,...
        demux_outHandle, demux_inHandle)
    p = get_param(demux_outHandle.Inport(inport_idx), 'Position');
    x = p(1) - 50*inport_idx;
    y = p(2);
    demux_path = strcat(new_model_name,'/Demux',inport_name);
    demux_pos(1) = (x - 10);
    demux_pos(2) = (y - 10);
    demux_pos(3) = (x + 10);
    demux_pos(4) = (y + 50 * dim);
    h = add_block('simulink/Signal Routing/Demux',...
        demux_path,...
        'MakeNameUnique', 'on', ...
        'Outputs', num2str(dim),...
        'Position',demux_pos);
    demux_Porthandl = get_param(h, 'PortHandles');
    add_line(new_model_name,...
        demux_inHandle.Outport(1),...
        demux_Porthandl.Inport(1), ...
        'autorouting', 'on');
    for j=1:dim
        add_line(new_model_name,...
            demux_Porthandl.Outport(j),...
            demux_outHandle.Inport(inport_idx), ...
            'autorouting', 'on');
        inport_idx = inport_idx + 1;
    end
end
        
