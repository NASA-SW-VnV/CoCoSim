function obj = substituteVars(obj, oldVar, newVar)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
    obj.exprs = cellfun(@(x) x.substituteVars(oldVar, newVar), obj.exprs, 'UniformOutput', 0);
    if isa(obj, 'nasa_toLustre.lustreAst.MergeBoolExpr')
        obj.true_expr = obj.true_expr.substituteVars(oldVar, newVar);
        obj.false_expr = obj.false_expr.substituteVars(oldVar, newVar);
        obj.clock = obj.clock.substituteVars(oldVar, newVar);
    end
end
