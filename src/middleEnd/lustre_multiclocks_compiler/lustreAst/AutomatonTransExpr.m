classdef AutomatonTransExpr < LustreExpr
    %AutomatonTransExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        condition;
        is_restart;
        restart_state;%String
        resume_state;%String
    end
    
    methods 
        function obj = AutomatonTransExpr(condition, is_restart, state_name)
            obj.condition = condition;
            obj.is_restart = is_restart;
            if is_restart
                obj.restart_state = state_name;
                obj.resume_state = '';
            else
                obj.restart_state = '';
                obj.resume_state = state_name;
            end
        end
        
        function code = print_lustrec(obj)
            if obj.is_restart
                code = sprintf('%s restart %s\n',...
                    obj.condition.print_lustre(), ...
                    obj.restart_state.print_lustre());
            else
                code = sprintf('%s resume %s\n',...
                    obj.condition.print_lustre(), ...
                    obj.resume_state.print_lustre());
            end
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec();
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec();
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec();
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec();
        end

    end

end

