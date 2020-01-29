function [inputs,lusInport_dt] = ...
        getBlockInputsNames_convInType2AccType(obj, parent, blk)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    widths = blk.CompiledPortWidths.Inport;
    RndMeth = blk.RndMeth;
    inputs = cell(1, numel(widths));
    for i=1:numel(widths)
        inputs{i} = nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
        
        inport_dt = blk.CompiledPortDataTypes.Inport{i};
        [lusInport_dt] = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
        %converts the input data type(s) to real

        if ~strcmp(lusInport_dt, 'real')
            [external_lib, conv_format] =...
                nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'real', RndMeth);
            if ~isempty(conv_format)
                obj.addExternal_libraries(external_lib);
                inputs{i} = cellfun(@(x) ...
                   nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                    inputs{i}, 'un', 0);
            end
        end
    end
end
