%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

function [x2, y2] = process_inputs(node_block_path, blk_inputs, ID, x2, y2)
    for i=1:numel(blk_inputs)
        if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end
        var_name = BUtils.adapt_block_name(blk_inputs(i).name, ID);
        inport_path = strcat(node_block_path,'/',var_name);
        inport_output =  strcat(node_block_path,'/',var_name,'_out');

        add_block('simulink/Ports & Subsystems/In1',...
            inport_path,...
            'Position',[x2 y2 (x2+50) (y2+50)]);
        [dt, dim] = Lus2SLXUtils.getArgDataType(blk_inputs(i));
        
        if strcmp(dt, 'bool')
            set_param(inport_path, 'OutDataTypeStr', 'boolean');
        elseif strcmp(dt, 'int')
            % keep it as inherit for MCDC
            %TODO: pass type information from Simulink if we have it.
            %set_param(inport_path, 'OutDataTypeStr', 'int32');
        elseif strcmp(dt, 'real')
            set_param(inport_path, 'OutDataTypeStr', 'double');
        end
        if prod(dim) > 1
            set_param(inport_path, 'PortDimensions', mat2str(dim));
        end
        %we create a GoTo block for this input
        add_block('simulink/Signal Routing/Goto',...
            inport_output,...
            'GotoTag',var_name,...
            'TagVisibility', 'local', ...
            'Position',[(x2+100) y2 (x2+150) (y2+50)]);

        SrcBlkH = get_param(inport_path,'PortHandles');
        DstBlkH = get_param(inport_output, 'PortHandles');
        add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
    end
end

