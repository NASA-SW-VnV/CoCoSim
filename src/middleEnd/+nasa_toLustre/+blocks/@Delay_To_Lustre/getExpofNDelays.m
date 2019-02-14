function code = getExpofNDelays(x0, u, d)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if d == 0
        code = u;
        %sprintf(' %s ' , u);
    else
        code = BinaryExpr(BinaryExpr.ARROW, ...
            x0, ...
            UnaryExpr(UnaryExpr.PRE, ...
                Delay_To_Lustre.getExpofNDelays(x0, u, d - 1)));
        %sprintf(' %s -> pre(%s) ', x0 , Delay_To_Lustre.getExpofNDelays(x0, u, D -1));
    end

end

