function [inputs, inports_dt] = getInputs(obj, parent, blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    widths = blk.CompiledPortWidths.Inport;
    inputs = cell(1, numel(widths));
    inports_dt = cell(1, numel(widths));
    for i=1:numel(widths)
        inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
        dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{i});
        if ~strcmp(dt, 'int')
            [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(dt, 'int');
            if ~isempty(conv_format)
                obj.addExternal_libraries(external_lib);
                inputs{i} = cellfun(@(x) ...
                   nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x), inputs{i}, 'un', 0);
            end
            dt = 'int';
        end
        inports_dt{i} = arrayfun(@(x) dt, (1:numel(inputs{i})), ...
            'UniformOutput', false);
    end
end


