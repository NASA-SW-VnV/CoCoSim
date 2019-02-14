function code = addValue(a, code, outLusDT)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if strcmp(outLusDT, 'int')
        v = IntExpr(int32(a));
    elseif strcmp(outLusDT, 'bool')
        v = BooleanExpr(a);
    else
        v = RealExpr(a);
    end
    code = BinaryExpr(BinaryExpr.ARROW, ...
            v, ...
            UnaryExpr(UnaryExpr.PRE, code));
end


