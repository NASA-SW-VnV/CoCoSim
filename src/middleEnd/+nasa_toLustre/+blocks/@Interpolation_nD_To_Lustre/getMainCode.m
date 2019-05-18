function [mainCode, main_vars] = getMainCode(...
    obj,blk, outputs, inputs, interpolation_nDWrapperExtNode, blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interpolation_nD
    
    outputDataType = blk.CompiledPortDataTypes.Outport{1};
    lus_out_type =...
        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
    indexInputPortDataType = blk.CompiledPortDataTypes.Inport{1};
    fractionInputPortDataType = blk.CompiledPortDataTypes.Inport{2};
    lus_index_type = ...
        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
        indexInputPortDataType);
    lus_fraction_type = ...
        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
        fractionInputPortDataType);
    index_conv_format = {};
    fraction_conv_format = {};
    
    if ~strcmp(lus_index_type,'int')
        RndMeth = blkParams.RndMeth;
        SaturateOnIntegerOverflow = blkParams.SaturateOnIntegerOverflow;
        [external_lib_i, index_conv_format] =...
            nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('int', ...
            lus_index_type, RndMeth, SaturateOnIntegerOverflow);
        if ~isempty(external_lib_i)
            obj.addExternal_libraries(external_lib_i);
        end
    end   

    if ~strcmp(lus_fraction_type,'real')
        RndMeth = blkParams.RndMeth;
        SaturateOnIntegerOverflow = blkParams.SaturateOnIntegerOverflow;
        [external_lib_i, fraction_conv_format] =...
            nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('real', ...
            lus_fraction_type, RndMeth, SaturateOnIntegerOverflow);
        if ~isempty(external_lib_i)
            obj.addExternal_libraries(external_lib);
        end
    end 

    NumberOfAdjustedTableDimensions = ...
        blkParams.NumberOfAdjustedTableDimensions;

    main_vars = cell(1,numel(outputs));
       
    % mainCode
    mainCode = cell(1, numel(outputs));
    for outIdx=1:numel(outputs)
        main_vars{outIdx} = ...
            nasa_toLustre.lustreAst.LustreVar(outputs{outIdx}, lus_out_type);

        nodeCall_inputs = cell(1, 2*NumberOfAdjustedTableDimensions);
        for i=1:NumberOfAdjustedTableDimensions
            % index
            if isempty(index_conv_format)
                nodeCall_inputs{(i-1)*2+1} = inputs{(i-1)*2+1};                
            else
                nodeCall_inputs{(i-1)*2+1} = ...
                    nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                    index_conv_format,inputs{(i-1)*2+1});
            end
            % fraction
            if isempty(fraction_conv_format)
                nodeCall_inputs{(i-1)*2+2} = inputs{(i-1)*2+2};
            else
                nodeCall_inputs{(i-1)*2+2} = ...
                    nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                    fraction_conv_format,inputs{(i-1)*2+2});
            end
            
            
        end
        
        mainCode{outIdx} = nasa_toLustre.lustreAst.LustreEq(...
            outputs{outIdx}, nasa_toLustre.lustreAst.NodeCallExpr(...
            interpolation_nDWrapperExtNode.name, nodeCall_inputs));
        
    end  

end
