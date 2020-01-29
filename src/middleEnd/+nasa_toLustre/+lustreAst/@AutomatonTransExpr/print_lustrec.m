function code = print_lustrec(obj, backend)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    if obj.is_restart
        code = sprintf('%s restart %s\n',...
            obj.condition.print(backend), ...
            obj.restart_state);
    else
        code = sprintf('%s resume %s\n',...
            obj.condition.print(backend), ...
            obj.resume_state);
    end
end
