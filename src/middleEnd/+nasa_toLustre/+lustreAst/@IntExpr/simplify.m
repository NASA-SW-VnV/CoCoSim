function new_obj = simplify(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
        if isnumeric(obj.value) && obj.value < 0
        % -1 => -(1)
        new_obj = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, nasa_toLustre.lustreAst.IntExpr(-obj.value));
    else
        new_obj = obj;
    end
end
