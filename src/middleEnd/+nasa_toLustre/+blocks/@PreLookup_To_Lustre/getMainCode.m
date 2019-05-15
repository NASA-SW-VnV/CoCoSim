function [mainCode, main_vars] = getMainCode(~,blk,outputs,inputs,...
    wrapperExtNode,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Pre_Lookup
    
    %TODO remove it from outputs, no need for it. vars are added in
    main_vars = {};
   
    for i=1:length(inputs{1})
        if ~blkParams.OutputIndexOnly
            lhs = {outputs{2*i-1}, outputs{2*i}};
        else
            lhs = outputs{i};
        end
        if strcmp(blk.BreakpointsDataSource, 'Input port')
            rhs = [inputs{1}(i), inputs{2}];
        else
            rhs = inputs{1}{i};
        end
        mainCode{i} = nasa_toLustre.lustreAst.LustreEq(lhs, ...
            nasa_toLustre.lustreAst.NodeCallExpr(wrapperExtNode.name, rhs));
    end

end
