function new_obj = deepCopy(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    new_assignments = cellfun(@(x) x.deepCopy(), obj.assignments, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
end
