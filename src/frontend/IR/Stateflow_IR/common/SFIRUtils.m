classdef SFIRUtils
    %SFIRUTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static = true)
        
        function action_Array = split_actions(actions)
            delim = '(;|\n)';
            action_Array = regexp(actions, delim, 'split');
            action_Array = action_Array(~strcmp(action_Array,''));
            action_Array = action_Array(~strcmp(action_Array,' '));
        end
        
        function result = to_lustre_syntax(label)
            expression = '&&';
            replace = ' and ';
            result = regexprep(label,expression,replace);
            
            expression = '\|\|';
            replace = ' or ';
            result = regexprep(result,expression,replace);
        end
        
        function t_sorted = sort_transitions(t_ens)
            n = numel(t_ens);
            execution_order = zeros(n,1);
            for i=1:n
                execution_order(i) = t_ens(i).ExecutionOrder;
            end
            [~, sorted_ind] = sort(execution_order);
            t_sorted = t_ens(sorted_ind);
        end
        
        function new_name = adapt_root_name(name)
            new_name = regexprep(name, '/', '_');
        end
        
        function [dt_str] = to_lustre_dt(simulink_dt)
            
            if strcmp(simulink_dt, 'logical') || strcmp(simulink_dt, 'boolean')
                dt_str = 'bool';
            elseif strncmp(simulink_dt, 'int', 3) || strncmp(simulink_dt, 'uint', 4) || strncmp(simulink_dt, 'fixdt(1,16,', 11) || strncmp(simulink_dt, 'sfix64', 6)
                dt_str = 'int';
            elseif strcmp(simulink_dt, 'real') || strcmp(simulink_dt, 'int') || strcmp(simulink_dt, 'bool')
                dt_str = simulink_dt;
            else
                dt_str = 'real';
            end
        end
        
        function [init] = default_InitialValue(v, dt)
            if strcmp(v, '')
                if strcmp(dt, 'int')
                    init = '0';
                elseif strcmp(dt, 'bool')
                    init = 'false';
                else
                    init = '0.0';
                end
            else
                init = v;
            end
            
        end
    end
    
end

