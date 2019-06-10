function [new_obj, varIds] = changePre2Var(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    varIds = {};
    new_assignments = cell(numel(obj.assignments), 1);
    for i=1:numel(obj.assignments)
        [new_assignments{i}, varIds_i] = obj.assignments{i}.changePre2Var();
        varIds = [varIds, varIds_i];
    end
    new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
end
