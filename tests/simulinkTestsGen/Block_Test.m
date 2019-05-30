classdef Block_Test
    %BLOCK_TEST : all other blocks test class inherit from this class
    properties
        
    end
    
    methods(Abstract)
        status = generateTests(obj, outputDir)
    end
    methods(Static)
        
        
        %%
        function status = connectBlockToInportsOutports(blk_path)
            status = 0;
            try
                parent = get_param(blk_path, 'Parent');
            catch
                parent = fileparts(blk_path);
            end
            blokPortHandles = get_param(blk_path, 'PortHandles');
            inputPorts = [blokPortHandles.Enable, ...
                blokPortHandles.Ifaction, ...
                blokPortHandles.Inport, ...
                blokPortHandles.Reset, ...
                blokPortHandles.Trigger];
            for i=1:numel(inputPorts)
                status = status + addInport(inputPorts(i));
            end
            for i=1:numel(blokPortHandles.Outport)
                status = status + addOutport(blokPortHandles.Outport(i));
            end
            BlocksPosition_pp(parent, 0);
            function status = addInport(newBlkPort)
                try
                    status = 0;
                    inport_name = fullfile(parent, 'In1');
                    inport_handle = add_block('simulink/Ports & Subsystems/In1',...
                        inport_name,...
                        'MakeNameUnique', 'on');
                    inportPortHandles = get_param(inport_handle, 'PortHandles');
                    add_line(parent,...
                        inportPortHandles.Outport(1), newBlkPort,...
                        'autorouting', 'on');
                catch Me
                    display_msg(Me.getReport(), ...
                        MsgType.DEBUG, 'Block_Test', '');
                    status = 1;
                end
            end
            function status = addOutport(newBlkPort)
                try
                    status = 0;
                    outport_name = fullfile(parent, 'Out1');
                    outport_handle = add_block('simulink/Ports & Subsystems/Out1',...
                        outport_name,...
                        'MakeNameUnique', 'on');
                    outportPortHandles = get_param(outport_handle, 'PortHandles');
                    add_line(parent,...
                        newBlkPort, outportPortHandles.Inport(1),...
                        'autorouting', 'on');
                catch Me
                    display_msg(Me.getReport(), ...
                        MsgType.DEBUG, 'Block_Test', '');
                    status = 1;
                end
            end
        end
        
        %% get block params from structur
        function blkParams = struct2blockParams(s)
            fdnames = fieldnames(s);
            blkParams = {};
            for j=1:length(fdnames)
                blkParams{end+1} = fdnames{j};
                blkParams{end+1} = s.(fdnames{j});
            end
        end
        
    end
end

