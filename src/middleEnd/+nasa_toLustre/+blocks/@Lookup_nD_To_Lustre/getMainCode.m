function [mainCode, main_vars] = getMainCode(obj, blk,outputs,inputs,...
    wrapperExtNode,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Lookup_nD

    % if outputDataType is not real, we need to cast outputs   
    
    main_vars = {};
    out_conv_format = {};
    external_lib = {};
    slx_outport_dt = blk.CompiledPortDataTypes.Outport{1};
    Lusoutport_dt = ...
        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_outport_dt);
    if ~strcmp(Lusoutport_dt, 'real')
        % use 'Nearest' and not blk RndMeth. see Documentation of the block
        %RndMeth = 'Nearest';
        RndMeth = blkParams.RndMeth;
        [external_lib, out_conv_format] = ...
            nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
            'real', slx_outport_dt, RndMeth, ...
            blk.SaturateOnIntegerOverflow);   
        if ~isempty(out_conv_format)
            obj.addExternal_libraries(external_lib);
        end
    end    
    
    
%     
%     [out_conv_format, external_lib]  = ...
%         nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_out_conv_format(...
%         blk,blkParams);
    if ~isempty(external_lib)
        obj.addExternal_libraries(external_lib);
    end     
        
    % mainCode
    mainCode = cell(1, numel(outputs));
    for outIdx=1:numel(outputs)
        nodeCall_inputs = cell(1, numel(inputs));
        for i=1:numel(inputs)
            nodeCall_inputs{i} = inputs{i}{outIdx};
        end
                
        if isempty(out_conv_format)
            mainCode{outIdx} = nasa_toLustre.lustreAst.LustreEq(...
                outputs{outIdx}, nasa_toLustre.lustreAst.NodeCallExpr(...
                wrapperExtNode.name, nodeCall_inputs));
        else
            % if outputDataType is not real, we need to cast outputs
            mainCode{outIdx} = nasa_toLustre.lustreAst.LustreEq(...
                outputs{outIdx}, ...
                nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                out_conv_format, ...
                nasa_toLustre.lustreAst.NodeCallExpr(...
                wrapperExtNode.name, nodeCall_inputs)));            
        end        
    end
    
end
