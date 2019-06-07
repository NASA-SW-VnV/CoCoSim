function [ ir ] = diagramBlockParams( ir )
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %DIAGRAMBLOCKPARAMS Add some parameters to the block diagram missing in the
    %original IR

    file_path = ir.meta.file_path;
    load_system(file_path);
    [~, file_name, ~] = fileparts(file_path);
    field_name = IRUtils.name_format(file_name);
    if isfield(ir, field_name)
        Cmd = [file_name, '([], [], [], ''compile'');'];
        eval(Cmd);
        if ~isfield(ir.(field_name), 'Name')
            ir.(field_name).Name = file_name;
            ir.(field_name).Origin_path = file_name;
            ir.(field_name).Path = field_name;
        end

        if ~isfield(ir.(field_name), 'CompiledSampleTime')
            [st, ph, Clocks] = SLXUtils.getModelCompiledSampleTime(file_name);
            ir.(field_name).CompiledSampleTime = [st, ph];
            ir.(field_name).AllCompiledSampleTimes = Clocks;
        end

        if ~isfield(ir.(field_name), 'Handle')
            ir.(field_name).Handle = get_param(file_name, 'Handle');
        end

        if ~isfield(ir.(field_name), 'BlockType')
            ir.(field_name).BlockType = 'block_diagram';
        end

        Cmd = [file_name, '([], [], [], ''term'');'];
        eval(Cmd);
    end

end

