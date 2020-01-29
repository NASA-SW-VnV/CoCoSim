function [mainCode, main_vars] = getMainCode(~,blk,outputs,inputs,...
    wrapperExtNode,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Pre_Lookup
    
    main_vars = {};
    nbInputs = length(inputs{1});
    for i=1:nbInputs
        
        if blkParams.OutputIndexOnly
            lhs = outputs{i};
        elseif strcmp(blkParams.OutputSelection, 'Index and fraction')
            lhs = {outputs{i}, outputs{nbInputs + i}};      
        else
            %'Index and fraction as bus'
            lhs = {outputs{2*i-1}, outputs{2*i}};            
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
