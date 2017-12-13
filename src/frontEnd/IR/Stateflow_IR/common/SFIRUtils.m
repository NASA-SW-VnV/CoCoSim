classdef SFIRUtils
    %SFIRUTILS Summary of this class goes here
    %   Detailed explanation goes here
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        
        function s = objToStruct(obj)
            warning off;
            if numel(obj) > 1
                [n, m] = size(obj);
                for i=1:n
                    for j=1:m
                        s(i,j) = SFIRUtils.objToStruct(obj(i,j));
                    end
                end
            else
                if isobject(obj)
                    s = struct(obj);
                    for f=fieldnames(s)'
                        s.(f{1}) = SFIRUtils.objToStruct(s.(f{1}));
                    end
                else
                    s = obj;
                end
            end
            warning on;
        end
    end
    
end

