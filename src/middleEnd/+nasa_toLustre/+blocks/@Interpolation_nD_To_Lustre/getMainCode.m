function [mainCode, main_vars] = getMainCode(...
        obj,blk, outputs, inputs, interpolation_nDWrapperExtNode, blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interpolation_nD
    
    NumberOfTableDimensions =  blkParams.NumberOfTableDimensions;
    main_vars = {};
    
    Lusoutport_dt = ...
        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
        blk.CompiledPortDataTypes.Outport{1});
    if ~strcmp(Lusoutport_dt, 'real')
        [external_lib, out_conv_format] = ...
            nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
            'real', Lusoutport_dt, 'Nearest', ...
            blk.SaturateOnIntegerOverflow);
        if ~isempty(out_conv_format)
            obj.addExternal_libraries(external_lib);
        end
    end
    % mainCode
    mainCode = cell(1, numel(outputs));
    for outIdx=1:numel(outputs)
        
        nodeCall_inputs = {};
        inputIdx = 1;
        for i=1:NumberOfTableDimensions
            % index
            nodeCall_inputs{end+1} = inputs{inputIdx}{outIdx};
            inputIdx = inputIdx +1;
            nodeCall_inputs{end+1} = inputs{inputIdx}{outIdx};
            inputIdx = inputIdx + 1;
            
        end
        for i=1:length(blkParams.Table)
            nodeCall_inputs{end+1} = inputs{inputIdx}{i};
        end

        mainCode{outIdx} = ...
            nasa_toLustre.lustreAst.LustreEq(...
            outputs{outIdx}, nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
            out_conv_format, ...
             nasa_toLustre.lustreAst.NodeCallExpr(...
            interpolation_nDWrapperExtNode.name, nodeCall_inputs)));
        
    end
    
end
