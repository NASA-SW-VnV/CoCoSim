function new_obj = simplify(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    if obj.is_restart
        state_name = obj.restart_state;
    else
        state_name = obj.resume_state;
    end
    new_obj = nasa_toLustre.lustreAst.AutomatonTransExpr(...
        obj.condition.simplify(), ...
        obj.is_restart, state_name);
end
