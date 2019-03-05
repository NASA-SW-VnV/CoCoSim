function code = addValue(a, code, outLusDT)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %L = nasa_toLustre.ToLustreImport.L;
    %import(L{:})
    if strcmp(outLusDT, 'int')
        v = nasa_toLustre.lustreAst.IntExpr(int32(a));
    elseif strcmp(outLusDT, 'bool')
        v = nasa_toLustre.lustreAst.BooleanExpr(a);
    else
        v = nasa_toLustre.lustreAst.RealExpr(a);
    end
    code = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            v, ...
            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, code));
end


