function code = print_lustrec(obj, backend)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    lines = cellfun(@(x) x.print(backend), obj.assignments, 'UniformOutput', 0);
    code = MatlabUtils.strjoin(lines, '\n\t');
end
