function code = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    if obj.OneLine
        code = sprintf('(if %s then %s else %s)', ...
            obj.condition.print(backend),...
            obj.thenExpr.print(backend), ...
            obj.ElseExpr.print(backend));
    else
        code = sprintf('if %s then\n\t\t%s\n\t    else %s', ...
            obj.condition.print(backend),...
            obj.thenExpr.print(backend), ...
            obj.ElseExpr.print(backend));
    end
    
end
