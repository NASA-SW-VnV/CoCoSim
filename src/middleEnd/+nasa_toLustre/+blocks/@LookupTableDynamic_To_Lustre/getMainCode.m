function [mainCode, main_vars] = getMainCode(obj, blk,outputs,inputs,...
    wrapperExtNode,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LookupTableDynamic_To_Lustre
    
    outputDataType = blk.CompiledPortDataTypes.Outport{1};
    lus_out_type =...
        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
    % if outputDataType is not real, we need to cast outputs   
    [output_conv_format, external_lib]  = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_output_conv_format(...
        blk,blkParams);
    if ~isempty(external_lib)
        obj.addExternal_libraries(external_lib);
    end      

    main_vars = cell(1,numel(outputs));
       
    % mainCode
    mainCode = cell(1, numel(outputs));
    for outIdx=1:numel(outputs)
        main_vars{outIdx} = ...
            nasa_toLustre.lustreAst.LustreVar(outputs{outIdx}, lus_out_type);
        
        nodeCall_inputs = cell(1,1+numel(inputs{2})+numel(inputs{3}));

        nodeCall_inputs{1} = inputs{1}{outIdx};
        counter = 1;
        for i=2:numel(inputs)
            for j=1:numel(inputs{i})
                counter = counter + 1;
                nodeCall_inputs{counter} = inputs{i}{j};
            end
        end
        if isempty(output_conv_format)
            mainCode{outIdx} = nasa_toLustre.lustreAst.LustreEq(...
                outputs{outIdx}, nasa_toLustre.lustreAst.NodeCallExpr(...
                wrapperExtNode.name, nodeCall_inputs));
        else
            % if outputDataType is not real, we need to cast outputs
            mainCode{outIdx} = nasa_toLustre.lustreAst.LustreEq(...
                outputs{outIdx}, ...
                nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                output_conv_format, ...
                nasa_toLustre.lustreAst.NodeCallExpr(...
                wrapperExtNode.name, nodeCall_inputs)));            
        end  
    end  
    
end
