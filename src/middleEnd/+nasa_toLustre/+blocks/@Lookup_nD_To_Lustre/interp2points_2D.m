function y_interp = interp2points_2D(x1, y1, x2, y2, x_interp)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    import nasa_toLustre.lustreAst.BinaryExpr
    % This function perform linear interpolation/extrapolation for
    % 2D from 2 points (x1,y1) and (x2, y2).
    % All parameters need to be LustreAst objects
    b1 = nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.MINUS,x2,x_interp); 
    b2 = nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.MINUS,x_interp,x1); 
    n1 = nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.MULTIPLY,y1,b1);
    n2 = nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.MULTIPLY,y2,b2);
    num = nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.PLUS,n1,n2);
    denum = nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.MINUS,x2,x1);            
    y_interp = nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.DIVIDE, num, denum);
end


