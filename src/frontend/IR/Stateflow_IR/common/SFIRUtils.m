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
    end
   
end

