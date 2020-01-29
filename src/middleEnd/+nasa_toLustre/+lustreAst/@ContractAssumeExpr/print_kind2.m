function code = print_kind2(obj, backend)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    if isempty(obj.id)
        code = sprintf('assume %s;', ...
            obj.exp.print(backend));
    else
        code = sprintf('assume "%s" %s;', ...
            obj.id, ...
            obj.exp.print(backend));
    end
end
