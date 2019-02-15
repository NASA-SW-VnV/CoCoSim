function [inputs, inports_dt] = getInputs(parent, blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    widths = blk.CompiledPortWidths.Inport;
    inputs = cell(1, numel(widths));
    inports_dt = cell(1, numel(widths));
    for i=1:numel(widths)
        inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
        dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(i));
        inports_dt{i} = arrayfun(@(x) dt, (1:numel(inputs{i})), ...
            'UniformOutput', false);
    end
end
