function new_obj = changeArrowExp(obj, cond)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_obj = nasa_toLustre.lustreAst.IteExpr(obj.condition.changeArrowExp(cond),...
        obj.thenExpr.changeArrowExp(cond),...
        obj.ElseExpr.changeArrowExp(cond),...
        obj.OneLine);
end
