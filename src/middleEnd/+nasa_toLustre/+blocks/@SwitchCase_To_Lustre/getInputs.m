function [inputs, inports_dt] = getInputs(obj, parent, blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
     % take the list of the inputs width, in the previous example,
    % "In1" has a width of 3 and "In2" has a width of 1.
    % So width = [3, 1].
    widths = blk.CompiledPortWidths.Inport;
    % Go over inputs, numel(widths) is the number of inputs. In
    % this example is 2 ("In1", "In2").
    inputs = cell(1, numel(widths));
    inports_dt = cell(1, numel(widths));
    for i=1:numel(widths)
        % fill the names of the ith input.
        % inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
        % and inputs{2} = {'In2_1'}
        inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
        dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(i));
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


