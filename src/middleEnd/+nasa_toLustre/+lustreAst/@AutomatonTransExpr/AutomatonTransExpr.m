classdef AutomatonTransExpr < nasa_toLustre.lustreAst.LustreExpr
    %AutomatonTransExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
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
        new_obj = deepCopy(obj)
        %% simplify expression
        new_obj = simplify(obj)
         %% nbOccuranceVar ignored in Automaton
        function nb_occ = nbOccuranceVar(varargin)
            nb_occ = 0;
        end
        %% substituteVars ignored in Automaton
        new_obj = substituteVars(obj, varargin)
        
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.condition}; obj.condition.getAllLustreExpr()];
        end
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        new_obj = changeArrowExp(obj, ~)
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = obj.condition.getNodesCalled();
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
        
        
        %%
        code = print(obj, backend)
        code = print_lustrec(obj, backend)
        code = print_kind2(obj)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)

    end

end

