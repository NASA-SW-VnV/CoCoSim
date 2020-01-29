function code = getExpofNDelays(x0, u, d)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    
    if d == 0
        code = u;
        %sprintf(' %s ' , u);
    else
        code = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            x0, ...
            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                nasa_toLustre.blocks.Delay_To_Lustre.getExpofNDelays(x0, u, d - 1)));
        %sprintf(' %s -> pre(%s) ', x0 , nasa_toLustre.blocks.Delay_To_Lustre.getExpofNDelays(x0, u, D -1));
    end

end

