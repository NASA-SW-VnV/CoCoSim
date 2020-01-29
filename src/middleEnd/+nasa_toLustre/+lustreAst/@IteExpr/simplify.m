function new_obj = simplify(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
        new_cond = obj.condition.simplify();
    new_then = obj.thenExpr.simplify();
    new_else = obj.ElseExpr.simplify();
    % simplify trivial if-and-else
    % if true then x else y => x
    if isa(obj.condition, 'nasa_toLustre.lustreAst.BoolExpr')
        if obj.condition.getValue()
            new_obj = new_then;
        else
            new_obj = new_else;
        end
        return;
        
    end
    new_obj = nasa_toLustre.lustreAst.IteExpr(new_cond, new_then, new_else, obj.OneLine);
    
end
