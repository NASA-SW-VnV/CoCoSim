function blk = creatInportsOutports(blk)
    content = struct();
    Inputs = blk.Inputs;
    Outputs = blk.Outputs;
    for i=1:numel(Inputs)
        in = Inputs{i};
        port = in.Port;
        in.Port = num2str(port);%as Inport
        in.BlockType = 'Inport';
        in.Origin_path = fullfile(blk.Origin_path, in.Name);
        in.Path = fullfile(blk.Path, in.Name);
        in.CompiledPortWidths.Outport = blk.CompiledPortWidths.Inport(port);
        in.CompiledPortWidths.Inport = [];
        in.CompiledPortDataTypes.Outport = blk.CompiledPortDataTypes.Inport(port);
        in.CompiledPortDataTypes.Inport = {};
        in.BusObject = '';
        content.(in.Name) = in;
    end
    for i=1:numel(Outputs)
        out = Outputs{i};
        port = out.Port;
        out.Port = num2str(port);%as Outport
        out.BlockType = 'Outport';
        out.Origin_path = fullfile(blk.Origin_path, out.Name);
        out.Path = fullfile(blk.Path, out.Name);
        out.CompiledPortWidths.Inport = blk.CompiledPortWidths.Outport(port);
        out.CompiledPortWidths.Outport = [];
        out.CompiledPortDataTypes.Inport = blk.CompiledPortDataTypes.Outport(port);
        out.CompiledPortDataTypes.Outport = {};
        out.BusObject = '';
        content.(out.Name) = out;
    end
    blk.Content = content;
end