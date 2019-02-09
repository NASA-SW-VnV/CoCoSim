function [blk, MF_DATA_MAP] = creatInportsOutports(blk)
    MF_DATA_MAP = containers.Map('KeyType', 'char', 'ValueType', 'any');
    content = struct();
    Inputs = blk.Inputs;
    Outputs = blk.Outputs;
    for i=1:numel(Inputs)
        in = Inputs{i};
        % add additional information to consider it as Simulink Inport
        port = in.Port;
        in.Port = num2str(port);%as Inport
        in.BlockType = 'Inport';
        in.Origin_path = fullfile(blk.Origin_path, in.Name);
        in.Path = fullfile(blk.Path, in.Name);
        in.CompiledPortWidths.Outport = blk.CompiledPortWidths.Inport(port);
        in.CompiledPortWidths.Inport = [];
        CompiledType = blk.CompiledPortDataTypes.Inport(port);
        in.CompiledPortDataTypes.Outport = CompiledType;
        in.CompiledPortDataTypes.Inport = {};
        in.BusObject = '';
        content.(in.Name) = in;
        % add input to data map
        MF_DATA_MAP(in.Name) = buildData(Inputs{i}, CompiledType);
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
        CompiledType = blk.CompiledPortDataTypes.Outport(port);
        out.CompiledPortDataTypes.Inport = CompiledType;
        out.CompiledPortDataTypes.Outport = {};
        out.BusObject = '';
        content.(out.Name) = out;
        % add input to data map
        MF_DATA_MAP(out.Name) = buildData(Outputs{i}, CompiledType);
    end
    blk.Content = content;
end
function data = buildData(d, CompiledType)
    data = d;
    data.LusDatatype = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( CompiledType);
    data.Datatype = CompiledType;
    data.CompiledType = CompiledType;
    data.InitialValue = '0';
end