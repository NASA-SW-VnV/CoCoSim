function [mainCode, main_vars] = getMainCode(~, blk,outputs,inputs,...
    wrapperExtNode,~)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LookupTableDynamic_To_Lustre
    
    outputDataType = blk.CompiledPortDataTypes.Outport{1};
    lus_out_type =...
        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);

    main_vars = cell(1,numel(outputs));
       
    % mainCode
    mainCode = cell(1, numel(outputs));
    for outIdx=1:numel(outputs)
        main_vars{outIdx} = ...
            nasa_toLustre.lustreAst.LustreVar(outputs{outIdx}, lus_out_type);
        
        nodeCall_inputs = {};

        nodeCall_inputs{end+1} = inputs{1}{outIdx};
        for i=2:numel(inputs)
            nodeCall_inputs = [nodeCall_inputs, inputs{i}];
        end

        mainCode{outIdx} = nasa_toLustre.lustreAst.LustreEq(...
            outputs{outIdx}, nasa_toLustre.lustreAst.NodeCallExpr(...
            wrapperExtNode.name, nodeCall_inputs));
        
    end  
    
end
