function [new_obj, varIds] = changePre2Var(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    varIds = {};
    new_exprs = {};
    for i=1:numel(obj.nodeArgs)
        [new_exprs{i}, varIds_i] = obj.nodeArgs{i}.changePre2Var();
        varIds = [varIds, varIds_i];
    end
    [condE, varId] = obj.cond.changePre2Var();
    varIds = [varIds, varId];
    new_obj = nasa_toLustre.lustreAst.EveryExpr(obj.nodeName, ...
        new_exprs, condE);
end
