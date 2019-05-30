function [inputs] = ...
        getBlockInputsNames_convInType2AccType(obj, parent, blk,isSelector)
    %% get block inputs names and also convert input signal data type to accumulated datatype but keep index assignment/selection as int  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isSelector
        inputIdToConvertToInt = 1;
    else
        inputIdToConvertToInt = 2;
    end
    inputs = {};
    widths = blk.CompiledPortWidths.Inport;
    %max_width = widths(1);
    outputDataType = blk.CompiledPortDataTypes.Outport{1};
    for i=1:numel(widths)
        inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
        inport_dt = blk.CompiledPortDataTypes.Inport{i};
        [lusInport_dt, ~] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
        
        %converts the input data type(s) to
        %its accumulator data type
        if ~strcmp(inport_dt, outputDataType) && i <= inputIdToConvertToInt
            [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
            if ~isempty(conv_format)
                obj.addExternal_libraries(external_lib);
                inputs{i} = cellfun(@(x) ...
                    nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                    inputs{i}, 'un', 0);
            end
        elseif i > inputIdToConvertToInt && ~strcmp(lusInport_dt, 'int')
            % convert index values to int for Lustre code
            [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'int');
            if ~isempty(conv_format)
                obj.addExternal_libraries(external_lib);
                inputs{i} = cellfun(@(x) ...
                    nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                    inputs{i}, 'un', 0);
            end
        end
    end
end
