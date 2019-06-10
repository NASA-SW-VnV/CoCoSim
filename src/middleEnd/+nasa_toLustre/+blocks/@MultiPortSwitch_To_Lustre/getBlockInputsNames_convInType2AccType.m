function [inputs] = getBlockInputsNames_convInType2AccType(obj, parent, blk)  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    widths = blk.CompiledPortWidths.Inport;
    nbInputs = numel(widths);
    max_width = max(widths);
    outputDataType = blk.CompiledPortDataTypes.Outport{1};
    RndMeth = blk.RndMeth;
    SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
    inputs = cell(1, nbInputs);
    for i=1:nbInputs
        inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
        if numel(inputs{i}) < max_width
            inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
        end
        inport_dt = blk.CompiledPortDataTypes.Inport{i};
        [inLusDT] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
        %converts the input data type(s) to
        %its accumulator data type
        if ~strcmp(inport_dt, outputDataType) && i~=1
            [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
            if ~isempty(conv_format)
                obj.addExternal_libraries(external_lib);
                inputs{i} = cellfun(@(x) ...
                   nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                    inputs{i}, 'un', 0);
            end
        elseif i==1 && ~strcmp(inLusDT, 'int')
            [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'int');
            if ~isempty(conv_format)
                obj.addExternal_libraries(external_lib);
                inputs{i} = cellfun(@(x)...
                   nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                    inputs{i}, 'un', 0);
            end
        end
    end
end

