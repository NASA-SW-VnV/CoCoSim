function new_obj = changeArrowExp(obj, cond)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    new_assignments = cellfun(@(x) x.changeArrowExp(cond), obj.assignments, 'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
end
