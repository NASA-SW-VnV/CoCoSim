function [mainCode, main_vars] = getMainCode(~, ~,~,inputs,...
    wrapperExtNode,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Pre_Lookup

    main_vars = wrapperExtNode.outputs;
    vars{1} = nasa_toLustre.lustreAst.VarIdExpr(main_vars{1});
    
    
    if ~blkParams.OutputIndexOnly
        vars{2} = nasa_toLustre.lustreAst.VarIdExpr(main_vars{2});
    end
    
    mainCode{1} = nasa_toLustre.lustreAst.LustreEq(vars, ...
        nasa_toLustre.lustreAst.NodeCallExpr(wrapperExtNode.name, inputs{1}));

end
