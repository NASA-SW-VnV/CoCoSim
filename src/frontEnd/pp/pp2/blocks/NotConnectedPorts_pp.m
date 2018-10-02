function [status, errors_msg] = NotConnectedPorts_pp( new_model_base )
%NotConnectedPorts_pp connects not connected ports to Constant or
%Terminator.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = 0;
errors_msg = {};

all_blocks = find_system(new_model_base,'LookUnderMasks', 'all');
if not(isempty(all_blocks))
    
    for i=1:length(all_blocks)
        try
            try
                obj = get_param(all_blocks{i},'Object');
                portsConection = obj.PortConnectivity';
            catch
                continue;
            end
            for p=portsConection
                try
                    if numel(p.SrcBlock) == 1 ...
                            && p.SrcBlock == -1
                        
                        ground_path = fullfile(obj.Parent, 'UnconnectedPort');
                        pos = p.Position;
                        x = pos(1);
                        y = pos(2);
                        constant_handle = add_block('simulink/Sources/Ground',...
                            ground_path,...
                            'MakeNameUnique', 'on', ...
                            'Position',[(x-30) (y-10) (x-10) (y+10)]);
                        SrcBlkH = get_param(constant_handle, 'PortHandles');
                        DstBlkH = obj.PortHandles;
                        
                        port_numer = str2double(p.Type);
                        line = get_param(DstBlkH.Inport(port_numer), 'line');
                        if line ~= -1
                            delete_line(line);
                        end
                        add_line(obj.Parent, SrcBlkH.Outport(1),...
                            DstBlkH.Inport(port_numer), 'autorouting', 'on');
                        
                    elseif  isempty(p.SrcBlock) && isempty(p.DstBlock)
                        terminator_path = fullfile(obj.Parent, 'UnconnectedPort');
                        pos = p.Position;
                        x = pos(1);
                        y = pos(2);
                        term_handle = add_block('simulink/Sinks/Terminator',...
                            terminator_path,...
                            'MakeNameUnique', 'on', ...
                            'Position',[(x+10) (y-10) (x+20) (y+10)]);
                        DstBlkH = get_param(term_handle, 'PortHandles');
                        SrcBlkH = obj.PortHandles;
                        
                        port_numer = str2double(p.Type);
                        line = get_param(SrcBlkH.Outport(port_numer), 'line');
                        if line ~= -1
                            delete_line(line);
                        end
                        add_line(obj.Parent, SrcBlkH.Outport(port_numer),...
                            DstBlkH.Inport(1), 'autorouting', 'on');
                        
                    end
                catch me
                    display_msg(me.getReport(), MsgType.DEBUG, 'NotConnectedPorts_pp', '');
                    continue;
                end
            end
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('NotConnectedPorts pre-process has failed for block %s', all_blocks{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'NotConnectedPorts_pp', '');
end

end