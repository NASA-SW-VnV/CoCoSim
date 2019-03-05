function [inputs,lusInport_dt,zero,one, external_lib] = ...
        getBlockInputsNames_convInType2AccType(parent, blk,isLookupTableDynamic)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %L = nasa_toLustre.ToLustreImport.L;
    %import(L{:})
    widths = blk.CompiledPortWidths.Inport;
    RndMeth = blk.RndMeth;
    max_width = max(widths);
    external_lib = '';
    for i=1:numel(widths)
        inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
        if ~isLookupTableDynamic && numel(inputs{i}) < max_width
            inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
        end
        inport_dt = blk.CompiledPortDataTypes.Inport(i);
        [lusInport_dt, zero, one] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
        %converts the input data type(s) to real

        if ~strcmp(lusInport_dt, 'real')
            [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'real', RndMeth);
            if ~isempty(conv_format)
                %obj.addExternal_libraries(external_lib);
                inputs{i} = cellfun(@(x) ...
                   nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                    inputs{i}, 'un', 0);
            end
        end
    end
end
