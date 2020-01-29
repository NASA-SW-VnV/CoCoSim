function new_obj = simplify(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    new_assignments = cellfun(@(x) x.simplify(), obj.assignments, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
end
