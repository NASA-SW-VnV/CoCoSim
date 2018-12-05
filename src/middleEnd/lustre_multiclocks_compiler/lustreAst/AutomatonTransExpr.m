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
        %% deepCopy
        function new_obj = deepCopy(obj)
            if obj.is_restart
                state_name = obj.restart_state;
            else
                state_name = obj.resume_state;
            end
            new_obj = AutomatonTransExpr(...
                obj.condition.deepCopy(), ...
                obj.is_restart, state_name);
        end
        %% simplify expression
        function new_obj = simplify(obj)
            if obj.is_restart
                state_name = obj.restart_state;
            else
                state_name = obj.resume_state;
            end
            new_obj = AutomatonTransExpr(...
                obj.condition.simplify(), ...
                obj.is_restart, state_name);
        end
         %% nbOccuranceVar ignored in Automaton
        function nb_occ = nbOccuranceVar(varargin)
            nb_occ = 0;
        end
        %% substituteVars ignored in Automaton
        function new_obj = substituteVars(obj, varargin)
            new_obj = obj;
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        function new_obj = changeArrowExp(obj, ~)
            new_obj = obj;
        end
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = obj.condition.getNodesCalled();
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            %TODO: Not done for this class yet, as it is not used by stateflow.
            new_obj = obj;
        end
        
        
        %%
        function code = print(obj, backend)
            %TODO: check if lustrec syntax is OK for jkind and prelude.
            code = obj.print_lustrec(backend);
        end
        function code = print_lustrec(obj, backend)
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
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(BackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(BackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(BackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(BackendType.PRELUDE);
        end

    end

end

