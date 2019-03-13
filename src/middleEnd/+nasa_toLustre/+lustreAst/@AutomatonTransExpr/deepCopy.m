function new_obj = deepCopy(obj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if obj.is_restart
        state_name = obj.restart_state;
    else
        state_name = obj.resume_state;
    end
    new_obj = nasa_toLustre.lustreAst.AutomatonTransExpr(...
        obj.condition.deepCopy(), ...
        obj.is_restart, state_name);
end
