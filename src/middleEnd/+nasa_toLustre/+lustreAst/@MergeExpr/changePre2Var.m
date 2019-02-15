function [new_obj, varIds] = changePre2Var(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    varIds = {};
    new_exprs = {};
    for i=1:numel(obj.exprs)
        [new_exprs{i}, varIds_i] = obj.exprs{i}.changePre2Var();
        varIds = [varIds, varIds_i];
    end
    new_obj = nasa_toLustre.lustreAst.MergeExpr(obj.clock, new_exprs);
end
