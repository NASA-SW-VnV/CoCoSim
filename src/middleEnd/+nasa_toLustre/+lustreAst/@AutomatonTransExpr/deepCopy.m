function new_obj = deepCopy(obj)
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
        obj.condition.deepCopy(), ...
        obj.is_restart, state_name);
end
