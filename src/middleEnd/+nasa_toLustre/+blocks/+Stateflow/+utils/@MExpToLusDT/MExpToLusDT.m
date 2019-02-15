classdef MExpToLusDT
    %MEXPTOLUSDT returns Lustre DataType of an expression
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    properties
    end
    
    methods(Static)
        % use alphabetic order
        dt = assignment_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
        dt = binaryExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
        dt = constant_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
        dt = expression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
        dt = fun_indexing_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
        dt = ID_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
        dt = matrix_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
        dt = parenthesedExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
        dt = struct_indexing_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
        dt = unaryExpression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun)
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
            import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
            if isempty(code) || ...
                    isempty(input_dt) || isempty(output_dt) 
                return;
            end
            if ischar(input_dt)
                input_dt = {input_dt};
            end
            if ischar(output_dt)
                output_dt = {output_dt};
            end
            [code, input_dt] = MExpToLusAST.inlineOperands(code, input_dt);
            [output_dt, input_dt] = MExpToLusAST.inlineOperands(output_dt, input_dt);
            for i=1:numel(code)
                if isequal(input_dt{i}, output_dt{i})
                    return;
                end
                conv = strcat(input_dt{i}, '_to_', output_dt{i});
                obj.addExternal_libraries(strcat('LustDTLib_', conv));
                code{i} = nasa_toLustre.lustreAst.NodeCallExpr(conv, {code{i}});
            end
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

