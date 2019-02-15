function [code, exp_dt] = mathFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, ~, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    import nasa_toLustre.utils.SLX2LusUtils
    % Do not forget to update exp_dt in each switch case if needed
    exp_dt = MExpToLusDT.expression_DT(tree, data_map, inputs, isSimulink, isStateFlow, isMatlabFun);
    tree_ID = tree.ID;
    
    switch tree_ID
        case  {'acos', 'acosh', 'asin', 'asinh', 'atan', ...
                'atanh', 'cbrt', 'cos', 'cosh',...
                'sqrt', 'exp', 'log', 'log10',...
                'sin','tan', 'sinh', 'trunc'}
            fun_name = tree_ID;
            BlkObj.addExternal_libraries('LustMathLib_lustrec_math');
            [param, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                parent, blk, data_map, inputs, 'real', ...
                isSimulink, isStateFlow, isMatlabFun);
            code = arrayfun(@(i) NodeCallExpr(fun_name, param{i}), ...
                (1:numel(param)), 'UniformOutput', false);
            exp_dt = 'real';
            
            
        case {'atan2', 'power', 'pow'}
            % two arguments
            BlkObj.addExternal_libraries('LustMathLib_lustrec_math');
            if isequal(tree_ID, 'power')
                fun_name = 'pow';
            else
                fun_name = tree_ID;
            end
            [param1, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                parent, blk, data_map, inputs, 'real', ...
                isSimulink, isStateFlow, isMatlabFun);
            [param2, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(2),...
                parent, blk, data_map, inputs, 'real', ...
                isSimulink, isStateFlow, isMatlabFun);
            
            
            % inline operands
            [param1, param2] = MExpToLusAST.inlineOperands(param1, param2, tree);
            
            code = arrayfun(@(i) NodeCallExpr(fun_name, {param1{i},param2{i}}), ...
                (1:numel(param1)), 'UniformOutput', false);
            exp_dt = 'real';
            
        case 'hypot'
            exp_dt = 'real';
            BlkObj.addExternal_libraries('LustMathLib_lustrec_math');
            [param1, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                parent, blk, data_map, inputs, 'real', ...
                isSimulink, isStateFlow, isMatlabFun);
            [param2, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(2),...
                parent, blk, data_map, inputs, 'real', ...
                isSimulink, isStateFlow, isMatlabFun);
            
            % sqrt(x*x, y*y)
            param1 = arrayfun(@(i) BinaryExpr(BinaryExpr.MULTIPLY, param1{i}, param1{i}), ...
                (1:numel(param1)), 'UniformOutput', false);
            param2 = arrayfun(@(i) BinaryExpr(BinaryExpr.MULTIPLY, param2{i}, param2{i}), ...
                (1:numel(param2)), 'UniformOutput', false);
            % inline operands
            [param1, param2] = MExpToLusAST.inlineOperands(param1, param2, tree);
            
            code = arrayfun(@(i) NodeCallExpr('sqrt', {param1{i},param2{i}}), ...
                (1:numel(param1)), 'UniformOutput', false);
            
        case {'abs', 'sgn'}
            expected_param_dt = exp_dt;
            if isequal(expected_param_dt, 'int') ...
                    || isequal(expected_param_dt, 'real')
                fun_name = strcat(tree_ID, '_', expected_param_dt);
            else
                fun_name = strcat(tree_ID, '_real');
                expected_param_dt = 'real';
            end
            lib_name = strcat('LustMathLib_', fun_name);
            BlkObj.addExternal_libraries(lib_name);
            
            [param, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                parent, blk, data_map, inputs, expected_param_dt, ...
                isSimulink, isStateFlow, isMatlabFun);
            code = arrayfun(@(i) NodeCallExpr(fun_name, param{i}), ...
                (1:numel(param)), 'UniformOutput', false);
            exp_dt = expected_param_dt;
            
            %function with two arguments
        case {'rem', 'mod'}
            [param1, param1_dt] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                parent, blk, data_map, inputs, '', ...
                isSimulink, isStateFlow, isMatlabFun);
            [param2, param2_dt] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(2),...
                parent, blk, data_map, inputs, '', ...
                isSimulink, isStateFlow, isMatlabFun);
            params_Dt = MExpToLusDT.upperDT(param1_dt, param2_dt);
            if isequal(params_Dt, 'int')
                fun_name = strcat(tree_ID, '_int_int');
                lib_name = strcat('LustMathLib_', fun_name);
                BlkObj.addExternal_libraries(lib_name);
                exp_dt = 'int';
            else
                BlkObj.addExternal_libraries('LustMathLib_simulink_math_fcn');
                fun_name = strcat(tree_ID, '_real');
                params_Dt = 'real';
                exp_dt = 'real';
            end
            % make sure parameter is converted to real
            param1 = MExpToLusDT.convertDT(BlkObj, param1, param1_dt, params_Dt);
            param2 = MExpToLusDT.convertDT(BlkObj, param2, param2_dt, params_Dt);
            
            % inline operands
            [param1, param2] = MExpToLusAST.inlineOperands(param1, param2, tree);
            
            code = arrayfun(@(i) NodeCallExpr(fun_name, {param1{i},param2{i}}), ...
                (1:numel(param1)), 'UniformOutput', false);
        otherwise
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" is not handled in Block %s',...
                tree.ID, blk.Origin_path);
            throw(ME);
    end
end

