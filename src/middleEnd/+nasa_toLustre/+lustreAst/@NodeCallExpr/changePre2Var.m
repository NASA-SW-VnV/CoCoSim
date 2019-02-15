function [new_obj, varIds] = changePre2Var(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    varIds = {};
    new_args = cell(numel(obj.args), 1);
    for i=1:numel(obj.args)
        [new_args{i}, varIds_i] = obj.args{i}.changePre2Var();
        varIds = [varIds, varIds_i];
    end
    new_obj = nasa_toLustre.lustreAst.NodeCallExpr(obj.nodeName, new_args);
end
