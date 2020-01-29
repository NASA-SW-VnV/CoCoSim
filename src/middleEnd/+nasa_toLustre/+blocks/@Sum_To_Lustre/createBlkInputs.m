%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function inputs = createBlkInputs(obj, parent, blk, widths, AccumDataTypeStr, isSumBlock)
    
    max_width = max(widths);

    RndMeth = blk.RndMeth;
    SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
    inputs = cell(1, numel(widths));
    for i=1:numel(widths)
        inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
        if numel(inputs{i}) < max_width
            if ~(~isSumBlock && strcmp(blk.Multiplication, 'Matrix(*)'))
                inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
            end
        end
        inport_dt = blk.CompiledPortDataTypes.Inport{i};
        %converts the input data type(s) to
        %its accumulator data type
        if ~strcmp(inport_dt, AccumDataTypeStr)
            [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, AccumDataTypeStr, RndMeth, SaturateOnIntegerOverflow);
            if ~isempty(conv_format)
                obj.addExternal_libraries(external_lib);
                inputs{i} = cellfun(@(x) ...
                   nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                    inputs{i}, 'un', 0);
            end
        end

    end
end
