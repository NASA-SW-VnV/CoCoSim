classdef If_To_Lustre < Block_To_Lustre
    % IF block generates boolean conditions that will be used with the
    % Action subsystems that are linked to.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            %% Step 1: Get the block outputs names, If a block is called X
            % and has one outport with width 3 and datatype double,
            % then outputs = {'X_1', 'X_2', 'X_3'}
            % and outputs_dt = {'X_1:real;', 'X_2:real;', 'X_3:real;'}
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            
            %% Step 2: add outputs_dt to the list of variables to be declared
            % in the var section of the node.
            obj.addVariable(outputs_dt);
            
            %% Step 3: construct the inputs names, if a block "X" has two inputs,
            % ("In1" and "In2")
            % "In1" is of dimension 3 and "In2" is of dimension 1.
            % Then inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
            % and inputs{2} = {'In2_1'}
            
            % we initialize the inputs by empty cell.
            inputs = {};
            % take the list of the inputs width, in the previous example,
            % "In1" has a width of 3 and "In2" has a width of 1.
            % So width = [3, 1].
            widths = blk.CompiledPortWidths.Inport;
            % Go over inputs, numel(widths) is the number of inputs. In
            % this example is 2 ("In1", "In2").
            for i=1:numel(widths)
                % fill the names of the ith input.
                % inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
                % and inputs{2} = {'In2_1'}
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                inports_dt{i} = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(i));
            end
            % get all expressions
            IfExp{1} =  blk.IfExpression;
            elseExp = split(blk.ElseIfExpressions, ',');
            IfExp = [IfExp; elseExp];
            if strcmp(blk.ShowElse, 'on')
                IfExp{end+1} = '';
            end
            %% Step 4: start filling the definition of each output
            code = If_To_Lustre.ifElseCode(parent, blk, outputs, ...
                inputs, inports_dt, IfExp);
            obj.setCode(code);
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
        
    end
    methods(Static)
        function code = ifElseCode(parent, blk, outputs, inputs, inports_dt, IfExp)
            codes = {};
            % Go over outputs
            nbOutputs=numel(outputs);
            for j=1:nbOutputs
                lusCond = If_To_Lustre.formatConditionToLustre(...
                    IfExp{j}, inputs, inports_dt, parent, blk);
                if j==nbOutputs && isempty(IfExp{j})
                    %default condition
                    codes{j} = sprintf('%s;\n\t', ...
                        If_To_Lustre.outputsValues(nbOutputs, j));
                elseif j==nbOutputs
                    %last condition
                    codes{j} = sprintf('if (%s) then %s else %s;\n\t', ...
                        lusCond, If_To_Lustre.outputsValues(nbOutputs, j), ...
                        If_To_Lustre.outputsValues(nbOutputs, 0));
                else
                    codes{j} = sprintf('if (%s) then %s else\n\t\t', ...
                        lusCond, If_To_Lustre.outputsValues(nbOutputs, j));
                end
                
            end
            code = sprintf('(%s) = %s', ...
                MatlabUtils.strjoin(outputs, ', '), MatlabUtils.strjoin(codes, ''));
        end
        function exp  = outputsValues(outputsNumber, outputIdx)
            values = arrayfun(@(x) 'false', (1:outputsNumber), 'UniformOutput', 0);
            if outputIdx > 0 && outputIdx <= outputsNumber
                values{outputIdx} = 'true';
            end
            exp = sprintf('(%s)', MatlabUtils.strjoin(values, ', '));
        end
        function exp = formatConditionToLustre(cond, inputs_cell, inputs_dt, parent, blk)
            %If Conditions uses only: <, <=, ==, ~=, >, >=, &, |, ~, (), unary-minus
            
            [S,T] = regexp(cond, '(&|\|)', 'split', 'tokens');
            if ~isempty(T)
                % handling & and |
                codes = {};
                for i=1:numel(S)
                    codes{i} = If_To_Lustre.formatConditionToLustre(S{i}, inputs_cell,inputs_dt, parent, blk);
                end
                exp = codes{1};
                for i=1:numel(T)
                    if strcmp(T{i}, '&')
                        exp = sprintf('%s and %s', exp, codes{i+1});
                    else
                        exp = sprintf('%s or %s', exp, codes{i+1});
                    end
                end
            else
                exp = strrep(cond, '==', '=');
                exp = strrep(exp, '~=', '<>');
                %check for variables in workspace or u1, ....
                tokens = regexp(cond, '[a-zA-z]\w*', 'match');
                for i=1:numel(tokens)
                    if ~isempty(regexp(tokens{i}, 'u\d+', 'match'))
                        % case of u1, u2, u3 ...
                        [~, T] = regexp(tokens{i}, 'u(\d+)', 'match', 'tokens');
                        uIndex = str2double(T{1});
                        % check if input is an array
                        if iscell(inputs_cell{uIndex}) && numel(inputs_cell{uIndex}) > 1
                            %Get Vector index
                            pattern = strcat(tokens{i}, '\s*\(\s*(\d+(\.\d+)?)\s*\)');
                            [~, T] = regexp(exp, pattern, 'match', 'tokens');
                            if ~isempty(T)
                                arrayIndex = str2double(T{1});
                                exp = regexprep(exp, pattern,inputs_cell{uIndex}{arrayIndex});
                            else
                                display_msg(sprintf('Unexpected expression %s in block "%s"', exp, blk.Origin_path),...
                                    MsgType.ERROR, 'If_To_Lustre.formatConditionToLustre', '');
                                return;
                            end
                        else
                            exp = regexprep(exp, strcat('(\W|^)',char(tokens{i}), '(\W|$)'), ...
                                sprintf('$1 %s $2', char(inputs_cell{uIndex})));
                        end
                        % replace constants to the input data type.
                        if strcmp(inputs_dt{uIndex}, 'real')
                            exp = regexprep(exp, '([^\w0-9\.]|^)(\d+)([^\w0-9\.]|$)', '$1 $2.0 $3');
                        end
                    else
                        % case of workspace or model workspace variables
                        [value, ~, status] = ...
                            Constant_To_Lustre.getValueFromParameter(parent, blk, tokens{i});
                        if status
                            display_msg(sprintf('Not found Variable "%s" in block "%s"', tokens{i}, blk.Origin_path),...
                                MsgType.ERROR, 'If_To_Lustre.formatConditionToLustre', '');
                            return;
                        end
                        exp = regexprep(exp, strcat('(\W|^)',tokens{i}, '(\W|$)'), ...
                            sprintf('$1 %.10f $2', value));
                        
                    end
                end
            end
        end
    end
    
end

