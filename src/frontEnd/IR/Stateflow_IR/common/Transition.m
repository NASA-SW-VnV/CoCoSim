classdef Transition
    %Transition :each transition is associated with an event, a condition, side
    %effect condition actions ac, transition actions at and a destination
    %d.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        id;
        event;
        condition;
        condition_act;
        transition_act;
        dest;
    end
    
    methods(Static = true)
        function obj = Transition(e, c, c_a, t_a, d, id)
            obj.event = e;
            obj.condition = c;
            obj.condition_act = c_a;
            obj.transition_act = t_a;
            obj.dest = d;
            obj.id = id;
        end
        
        function t_obj = create_object(t)
            dest_state = t.Destination;
            transition_label = t.LabelString;
            [e, c, c_a, t_a] = Transition.extract_transition_fields(transition_label);
            if strcmp(dest_state.Type,'CONNECTIVE') || strcmp(dest_state.Type,'HISTORY')
                destination.type = 'Junction';
                destination.name = fullfile(dest_state.Path, strcat('Junction',num2str(dest_state.Id)));
            else
                destination.type = 'State';
                destination.name = fullfile(dest_state.Path, dest_state.Name);
            end
            t_obj = Transition(e, c, c_a, t_a, destination, t.ID);
        end
        
        function [event, condition, condition_action, transition_action] = extract_transition_fields(transition_label)
            % remove comments
            expression = '(\n|\s*|\.{3}|/\*(\s*\w*\W*\s*)*\*/)';
            replace = '';
            label_mod = regexprep(transition_label,expression,replace);
            
            % Lustre syntax
            % change == to =
            expression = '={2}';
            replace = '=';
            label_mod = regexprep(label_mod,expression,replace);
            
            expression = '(\[)(\w+\s*(,\s*\w+)+)(\])';
            replace = '($2)';
            label_mod = regexprep(label_mod,expression,replace);
            
            expression = '(!|~)([^=]\w*)';
            replace = 'not $2';
            label_mod = regexprep(label_mod,expression,replace);
            
            expression = '!=';
            replace = '<>';
            label_mod = regexprep(label_mod,expression,replace);
            
            expression = '~=';
            replace = '<>';
            label_mod = regexprep(label_mod,expression,replace);
            
            expression = '%%';
            replace = ' mod ';
            label_mod = regexprep(label_mod,expression,replace);
            
            pattern = Transition.transition_pattern();
            operands = regexp(label_mod,pattern,'tokens','once');
            
            if ~isempty(operands)
                event =operands{1};
                condition =operands{2};
                if ~isempty(condition)
                    condition = SFIRUtils.to_lustre_syntax(condition(2:end-1));
                end
                condition_action =operands{3};
                if ~isempty(condition_action)
                    condition_action = SFIRUtils.split_actions(condition_action(2:end-1));
                end
                transition_action =operands{4};
                if ~isempty(transition_action)
                    if contains(transition_action, '{')
                        transition_action = SFIRUtils.split_actions(transition_action(3:end-1));
                    else
                        transition_action = SFIRUtils.split_actions(transition_action(2:end));
                    end
                end
            else
                event ='';
                condition ='';
                condition_action ='';
                transition_action ='';
            end
        end
        
        function pattern = transition_pattern()
            %example of transition
            %E[!(SENSOR_IN_Flow_Rate_Monitored > f(IM_IN_Flow_Rate_Commanded, ((100 + CONST_IN_Tolerance_Min) /100)))]{overInfusion=2;}
            %[(IM_IN_Current_System_Mode = 6 or IM_IN_Current_System_Mode = 7 or  IM_IN_Current_System_Mode = 8 ) and  Step_Scaling_Factor(CONST_IN_Max_Paused_Duration,step_size) = 1]
            
            pf = '\s*[\)]*\s*';
            po = '\s*[\(]*\s*' ;
            number = '([-+]?\d*\.?\d+)'; %i.e 2.3, -2, +3.2
            ident = '([a-zA-Z][a-zA-Z_0-9]*)';
            multiple_ident = '(\[|\()(\w+(,\w+)+)(\]|\))';
            event_exp    =  strcat(ident,'?\s*');
            
            negation_exp = '(~|!|not)?'; % "!" is changed to "not" by section above
            var_or_number = strcat('(',number,'|',ident,')');
            basic_exp = strcat('(',po,negation_exp,var_or_number,pf,')'); % like x, 16, x_1, (((x)))))), ...
            math_op = '(+|+{2}|-|-{2}|*|/|\^|mod)'; % "%%" is changed to "mod" by section above
            basic_math_expression = strcat('(',po,basic_exp,'(',math_op,basic_exp ,')?',pf,')');% like x+y (x + y), ((x) - (y)), x, y
            multiple_math_exp = strcat('(','(',po,basic_math_expression,'(',math_op,basic_math_expression ,')*',pf,')*',')');
            
            function_call = strcat('(',po,ident,'\(','(',multiple_math_exp ,'[,\.]?',')*','\)',pf,')');
            exp  = strcat('(',function_call,'|',multiple_math_exp,')');
            
            comparison = '(=|>=?|<=?|!=|~=|<>)'; % "==" changed to "=" by section above
            basic_condition = strcat('(',po,negation_exp,exp,'(',comparison,exp ,')?',pf,')');
            cond_op = '([\|&]{2}|[\|&])'; % we can add "&" and "|"  :Bitwise AND , OR of two operands
            multiple_conditions = strcat('(','(',po,basic_condition,'(',cond_op,basic_condition ,')*',pf,')*',')');
            condition_exp = strcat('(\[',multiple_conditions,'\])?\s*');
            
            assignement_op = '\s*[+\-*/]?=\s*';%'\s*(=|+=|-=|*=|/=)\s*';
            inc_dec = '+{2}|-{2}';
            affectation = strcat('(','(',ident,'|', multiple_ident, ')','(',assignement_op,exp,'|',inc_dec,')',')');
            aff_or_fun = strcat('(',affectation,'|',function_call,')');
            multiple_aff_or_fun = strcat('(','(',aff_or_fun ,';?\s*)*',')');
            cond_action_exp = strcat('({',multiple_aff_or_fun,'})?\s*');
            trans_action_exp= strcat('(/{?',multiple_aff_or_fun,'}?)?\s*');
            pattern = strcat(event_exp,condition_exp,cond_action_exp,trans_action_exp);
        end
        
        
    end
    
end

