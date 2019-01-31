classdef SFIRPPUtils
    %SFIRPPUtils Summary of this class goes here
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
        
        
        function new_name = adapt_root_name(name)
            new_name = regexprep(...
                SLX2LusUtils.name_format(name), '/', '_');
        end
        
        function action_Array = split_actions(actions)
            
            if ~isempty(actions) && iscell(actions)
                actions = actions(~strcmp(actions, ''));
                actions = MatlabUtils.strjoin(actions, '\n');
            end
            % clean actions from comments 
            actions = regexprep(actions, '/\*.+\*/', '');
            delim = '(;|\n)';
            action_Array = regexp(actions, delim, 'split');
            action_Array = cellfun(@(x) regexprep(x, '\s+', ''), ...
                action_Array, 'UniformOutput', false);
            action_Array = action_Array(~strcmp(action_Array,''));
        end%split_actions
        
        function [dt_str] = to_lustre_dt(simulink_dt)
            dt_str = SLX2LusUtils.get_lustre_dt( simulink_dt);
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
        
        %%
        function [ actions_struct] = extractInputsOutputs(actions, data, isCondition)
            
            
            actions_struct.inputs = {};
            actions_struct.outputs = {};
            if nargin < 3
                isCondition = false;
            end            
            data_names = cellfun(@(x) x.Name, data, 'UniformOutput', false);
            for act_idx=1:numel(actions)
                action = actions{act_idx};
                
                expression = '(\s|;)';
                replace = '';
                action_updated = regexprep(action,expression,replace);
                
                expression = '/\*(\s*\w*\W*\s*)*\*/';
                replace = '';
                right_expression = regexprep(action_updated,expression,replace);
                
                % handle x++, x--, x+= 1, x = x + 1 ...
                expression = '(+{2}|-{2}|[+\-*/]=|={1})';
                [operands, ~] = regexp(action_updated,expression,'split','tokens');
                left_operand =operands{1};
                
                right_expression = action_updated;
                
                %update equation dataTypes and refresh variables names
                if isempty(data) && ~isCondition
                    return;
                end
                d = data(strcmp(data_names,left_operand));
                data_found = 0;
                if isempty(d)
                    if MatlabUtils.contains(action, '[')
                        vec = regexp(action,'\[','split');
                        d = data(strcmp(data_names,vec{1}));
                        if ~isempty(d)
                            data_found = 1;
                        end
                    end
                else
                    data_found = 1;
                end
                
                if ~data_found && ~isCondition
                    return;
                end
               
                
                expression = '([a-zA-Z_]\w*)';
                tokens = regexp(right_expression, expression, 'tokens');
                for i=1:numel(tokens)
                    d = data(strcmp(data_names,tokens{i}));
                    if ~isempty(d)
                        actions_struct.inputs{end+1}= d{1};
                    end
                end
                
                
                %END
                d_idx = find(strcmp(data_names,left_operand));
               if ~isempty(d_idx)
                actions_struct.outputs{end+1} = data{d_idx};
               end

            end
        end
        %%
        function [action_updated, data, actions_struct, external_nodes] = adapt_action(action, data, actions_struct_in, isCondition)
            data_names = cellfun(@(x) x.Name, data, 'UniformOutput', false);
            external_nodes = [];
            if nargin < 3 || isempty(actions_struct_in)
                actions_struct.inputs = {};
                actions_struct.outputs = {};
            else
                actions_struct = actions_struct_in;
            end
            if nargin < 4
                isCondition = false;
            end
            expression = '(\s|;|\])';
            replace = '';
            action_updated = regexprep(action,expression,replace);
            
            %for arrays x[1][3] -> x_1_3
            expression = '(\w)+(\[)';
            replace = '$1_';
            action_updated = regexprep(action_updated,expression,replace);
            expression = '\[';
            replace = '';
            action_updated = regexprep(action_updated,expression,replace);
            expression = '/\*(\s*\w*\W*\s*)*\*/';
            replace = '';
            action_updated = regexprep(action_updated,expression,replace);
            
            % handle x++, x--, x+= 1, x = x + 1 ...
            expression = '(+{2}|-{2}|[+\-*/]=|={1})';
            [operands, tokens] = regexp(action_updated,expression,'split','tokens');
            left_operand =operands{1};
            if numel(operands) >1
                right_operand = operands{2};
                token = tokens{1};
            else
                right_operand = '';
                token = '';
            end
            
            expression = '(=|+{2}|\-{2})';
            [operands, ind] = regexp(action_updated,expression,'split','end');
            switch char(token)
                case '+='
                    right_expression = [left_operand ' + ' right_operand];
                    action_updated = [left_operand, ' = ' right_expression];
                case '-='
                    right_expression = [left_operand ' - ' right_operand];
                    action_updated = [left_operand, ' = ' right_expression];
                case '*='
                    right_expression = [left_operand ' * ' right_operand];
                    action_updated = [left_operand, ' = ' right_expression];
                case '/='
                    right_expression = [left_operand ' / ' right_operand];
                    action_updated = [left_operand, ' = ' right_expression];
                otherwise
                    right_expression = '';
                    if MatlabUtils.contains(action_updated,'++')
                        right_expression = strcat(operands{1},' + 1');
                    elseif MatlabUtils.contains(action_updated,'--')
                        right_expression = strcat(operands{1},' - 1');
                    else
                        if ~isempty(ind) && numel(action_updated)>=ind(1)+1
                            right_expression =action_updated(ind(1)+1:end);
                            if MatlabUtils.contains(right_expression,'==')
                                expression = '={2}';
                                replace = '=';
                                right_expression = regexprep(right_expression,expression,replace);
                            end
                        else
                            right_expression = action_updated;
                        end
                        
                    end
                    
            end
            
            %update equation dataTypes and refresh variables names
            if isempty(data) && ~isCondition
                return;
            end
            d = data(strcmp(data_names,left_operand));
            data_found = 0;
            if isempty(d)
                if MatlabUtils.contains(action, '[')
                    vec = regexp(action,'\[','split');
                    d = data(strcmp(data_names,vec{1}));
                    if ~isempty(d)
                        data_found = 1;
                    end
                end
            else
                data_found = 1;
            end
            
            if ~data_found && ~isCondition
                return;
            end
            if isCondition
                datatype = 'bool';
            else
                datatype = SFIRPPUtils.to_lustre_dt(d.datatype);
            end
            operator ='(\(|\)|\s|+|-|*|/|[!]?=|<>|&|<[=]?|>[=]?|\||,|^|$)';
            if strcmp(datatype,'real')
                if (MatlabUtils.contains(action_updated,'++') || MatlabUtils.contains(action_updated,'--')) && isempty(strfind(operands{2},'.'))
                    % fix x+1 or x-1 to x+1.0, x-1.0
                    expression = '(\<|[=+{2}\-{2}]\s*)(\d+)';
                    replace = '$1$2.0';
                    right_expression =  regexprep(right_expression, expression, replace);
                else
                    % wherever there is op constant, such as +1, -1, >1,
                    % .... the constant should be real number.
                    
                    expression =strcat(operator, '(\d+)', operator);
                    replace = '$1$2.0$3';
                    right_expression =  regexprep(right_expression, expression, replace);
                    
                end
            elseif strcmp(datatype,'bool')
                expression = '(^\s*)(1)';
                replace = '$1true';
                right_expression =  regexprep(right_expression,expression,replace);
                expression = '(^\s*)(0)';
                replace = '$1false';
                right_expression =  regexprep(right_expression,expression,replace);
            end
            
            
            
            
            
            
            
            %x = x + 1 -> x__2 = x__1 + 1;
            expression = '([a-zA-Z_]\w*)';
            tokens = regexp(right_expression, expression, 'tokens');
            for i=1:numel(tokens)
                d = data(strcmp(data_names,tokens{i}));
                if isempty(d)
                    %possibly tokens{i} is an array and as its name has changed we should
                    %extract the old name
                    vec = regexp(tokens{i},'(\<[a-zA-Z][a-zA-Z0-9]*)_\d*','tokens','once');
                    d = data(strcmp(data_names,char(vec{1})));
                    if ~isempty(d)
                        vector_size = d{1}.array_size;
                        if isempty(vector_size)
                            d = [];
                        end
                    end
                end
                if ~isempty(d)
                    % found a variable that should be indexed with its
                    % current index
                    dataScope = d{1}.scope;
                    if isfield(d{1}, 'index')
                        data_index = d{1}.index;
                    else
                        data_index = 1;
                    end
                    if strcmp(dataScope,'Output') || strcmp(dataScope,'Local')
                        expression = strcat(operator,'(', char(tokens{i}), ')',operator);
                        replace = strcat('$1 $2__', num2str(data_index), ' $3');
                        right_expression = regexprep(right_expression,expression,replace);
                        actions_struct.inputs{numel(actions_struct.inputs)+1}= d{1};
                    elseif strcmp(dataScope,'Input') || strcmp(dataScope,'Constant') || strcmp(dataScope,'Parameter')
                        actions_struct.inputs{numel(actions_struct.inputs)+1}= d{1};
                    else
                        error('DataScope :%s is not supported yet',dataScope)
                    end
                else
                    
                    [right_expression, external_nodes] =...
                        SFIRPPUtils.external_function_to_lustre(tokens{i},...
                        right_expression, external_nodes, datatype);
                end
            end
            
            % x = y==1 -> x = y=1 -> x = if y=1 then 1 else 0
            if ~isempty(strfind(right_expression,'='))
                if strcmp(datatype,'int')
                    right_expression = ['if ' right_expression ' then 1 else 0'] ;
                elseif strcmp(datatype,'real')
                    right_expression = ['if ' right_expression ' then 1.0 else 0.0'] ;
                end
            end
            
            %END
            if ~isCondition
                d_idx = find(strcmp(data_names,left_operand));
                if isfield(data{d_idx}, 'index') && ~isempty(data{d_idx}.index)
                    index = data{d_idx}.index + 1;
                else
                    index = 2;
                end
                data{d_idx}.index = index;
                A = cellfun(@(x) {x.name}, actions_struct.outputs);
                idx = find(strcmp(A,left_operand));
                if isempty(idx)
                    actions_struct.outputs{numel(actions_struct.outputs)+1} = data{d_idx};
                else
                    actions_struct.outputs{idx} = data{d_idx};
                end
                action_updated = [left_operand, '__', num2str(index), ' = ' right_expression ';'];
            else
                if ~isempty(left_operand) && MatlabUtils.contains(action, '=')
                    action_updated = [left_operand, ' = ' right_expression];
                    
                else
                    action_updated = right_expression;
                end
            end
        end
        
        
        
        %%
        function [right_expression, external_nodes] = external_function_to_lustre(token, right_expression, external_nodes, dt)
            % this part should be more developped, it is the case where
            % we call extern functions in actions as min, max, matlab
            % functions and others. We support until now min and max
            % functions whit integer parameters.
            if strcmp(char(token),'min')
                external_nodes = [external_nodes, struct('Name','min','Type', dt)];
                
            elseif strcmp(char(token),'max')
                external_nodes = [external_nodes, struct('Name','max','Type',dt)];
                
            elseif strcmp(char(token),'acos') ||  strcmp(char(token),'asin') ...
                    || strcmp(char(token),'atan') || strcmp(char(token),'atan2') ...
                    || strcmp(char(token),'cos') || strcmp(char(token),'sin') || strcmp(char(token),'tan')...
                    || strcmp(char(token),'acosh') || strcmp(char(token),'asinh') ...
                    || strcmp(char(token),'atanh')|| strcmp(char(token),'cosh') ...
                    || strcmp(char(token),'ceil') || strcmp(char(token),'erf') ...
                    || strcmp(char(token),'cbrt') || strcmp(char(token),'fabs') ...
                    || strcmp(char(token),'pow')  || strcmp(char(token),'sinh')...
                    || strcmp(char(token),'sqrt')
                external_nodes = [external_nodes, struct('Name','lustrec_math','Type',char(token))];
                
            elseif strcmp(char(token),'uint8') || strcmp(char(token),'uint16') || strcmp(char(token),'uint32')...
                    || strcmp(char(token),'int8') || strcmp(char(token),'int16') || strcmp(char(token),'int32')
                external_nodes = [external_nodes, struct('Name','conv','Type','real_to_int')];
                right_expression = regexprep(right_expression,char(token),'real_to_int');
                
            elseif strcmp(char(token),'double') || strcmp(char(token),'single')
                external_nodes = [external_nodes, struct('Name','conv','Type','int_to_real')];
                right_expression = regexprep(right_expression,char(token),'int_to_real');
                
                
            elseif ~strcmp(char(token),'true') && ~strcmp(char(token),'false')
                
                display_msg(...
                    sprintf('Token %s has not been processed',char(token)),...
                    MsgType.ERROR,...
                    'SFIRPPUtils',...
                    '');
            end
        end
        
        
        
        
    end
    
end

