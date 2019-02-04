classdef MExpToLusDT
    %MEXPTOLUSDT returns Lustre DataType of an expression
    
    properties
    end
    
    methods(Static)
        dt = assignment_DT(tree, data_map, inputs, isSimulink, isStateFlow)
        dt = binaryExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow)
        dt = constant_DT(tree, data_map, inputs, isSimulink, isStateFlow)
        dt = expression_DT(tree, data_map, inputs, isSimulink, isStateFlow)
        dt = fun_indexing_DT(tree, data_map, inputs, isSimulink, isStateFlow)
        dt = ID_DT(tree, data_map, inputs, isSimulink, isStateFlow)
        dt = parenthesedExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow)
        dt = unaryExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow)
    end
    
    methods(Static)
        %Utils
        function dt = getVarDT(data_map, var_name)
            if ~isKey(data_map, var_name)
                dt = '';
                return;
            end
            if isfield(data_map(var_name), 'LusDatatype')
                dt = data_map(var_name).LusDatatype;
            elseif ischar(data_map(var_name))
                dt = data_map(var_name);
            else
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Variable data_map is not well defined');
                throw(ME);
            end
        end
        
        function code = convertDT(obj, code, input_dt, output_dt)
            
            if isempty(code) || ...
                    isempty(input_dt) || isempty(output_dt) ||...
                    (iscell(input_dt) && numel(input_dt) > 1) || ...
                    (iscell(output_dt) && numel(output_dt) > 1)
                return;
            end
            if iscell(input_dt)
                input_dt = input_dt{1};
            end
            if iscell(output_dt)
                output_dt = output_dt{1};
            end
            if isequal(input_dt, output_dt)
                return;
            end
            conv = strcat(input_dt, '_to_', output_dt);
            obj.addExternal_libraries(strcat('LustDTLib_', conv));
            code = {nasa_toLustre.lustreAst.NodeCallExpr(conv, code)};
        end
        
        function dt = upperDT(left_dt, right_dt)
            if isempty(left_dt) && isempty(right_dt)
                dt = '';
                return;
            end
            if isempty(left_dt)
                dt = right_dt;
                return;
            end
            if isempty(right_dt)
                dt = left_dt;
                return;
            end
            if isequal(left_dt, 'real') || isequal(right_dt, 'real')
                dt = 'real';
            elseif isequal(left_dt, 'int') || isequal(right_dt, 'int')
                dt = 'int';
            else
                dt = 'bool';
            end
        end
        
    end
end

