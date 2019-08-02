function [code, exp_dt, dim, extra_code] = mathFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
            
    % Do not forget to update exp_dt in each switch case if needed
    exp_dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree, args);
    tree_ID = tree.ID;
    extra_code = {};

    switch tree_ID
        case  {'acos', 'acosh', 'asin', 'asinh', 'atan', ...
                'atanh', 'cbrt', 'cos', 'cosh',...
                'sqrt', 'exp', 'log', 'log10',...
                'sin','tan', 'sinh', 'trunc'}
            fun_name = tree_ID;
            args.blkObj.addExternal_libraries('LustMathLib_lustrec_math');
            args.expected_lusDT = 'real';
            [param, ~, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
            code = arrayfun(@(i) nasa_toLustre.lustreAst.NodeCallExpr(fun_name, param{i}), ...
                (1:numel(param)), 'UniformOutput', false);
            exp_dt = 'real';
            
            
        case {'atan2', 'power', 'pow'}
            % two arguments
            args.blkObj.addExternal_libraries('LustMathLib_lustrec_math');
            if strcmp(tree_ID, 'power')
                fun_name = 'pow';
            else
                fun_name = tree_ID;
            end
            args.expected_lusDT = 'real';
            [param1, ~, dim1, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.parameters(1), args);
            [param2, ~, dim2, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.parameters(2), args);
            extra_code = MatlabUtils.concat(extra_code, extra_code_i);
            if numel(dim1) > numel(dim2)
                dim = dim1;
            else
                dim = dim2;
            end
            
            % inline operands
            [param1, param2] = nasa_toLustre.utils.MExpToLusAST.inlineOperands(param1, param2, tree);
            
            code = arrayfun(@(i) nasa_toLustre.lustreAst.NodeCallExpr(fun_name, {param1{i},param2{i}}), ...
                (1:numel(param1)), 'UniformOutput', false);
            exp_dt = 'real';
            
        case 'hypot'
            exp_dt = 'real';
            args.blkObj.addExternal_libraries('LustMathLib_lustrec_math');
            args.expected_lusDT = 'real';
            [param1, ~, dim1, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.parameters(1), args);
            [param2, ~, dim2, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.parameters(2), args);
            extra_code = MatlabUtils.concat(extra_code, extra_code_i);
            % sqrt(x*x, y*y)
            param1 = arrayfun(@(i) nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, param1{i}, param1{i}), ...
                (1:numel(param1)), 'UniformOutput', false);
            param2 = arrayfun(@(i) nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, param2{i}, param2{i}), ...
                (1:numel(param2)), 'UniformOutput', false);
            % inline operands
            [param1, param2] = nasa_toLustre.utils.MExpToLusAST.inlineOperands(param1, param2, tree);
            
            code = arrayfun(@(i) nasa_toLustre.lustreAst.NodeCallExpr('sqrt', {param1{i},param2{i}}), ...
                (1:numel(param1)), 'UniformOutput', false);
            
            if numel(dim1) > numel(dim2)
                dim = dim1;
            else
                dim = dim2;
            end
            
        case {'abs', 'sgn', 'sign'}
            % TODO sgn only return scalar and not vector
            if strcmp(tree_ID, 'sgn')
                tree_ID = 'sign';
            end
            expected_param_dt = exp_dt;
            if strcmp(expected_param_dt, 'int') ...
                    || strcmp(expected_param_dt, 'real')
                fun_name = strcat(tree_ID, '_', expected_param_dt);
            else
                fun_name = strcat(tree_ID, '_real');
                expected_param_dt = 'real';
            end
            lib_name = strcat('LustMathLib_', fun_name);
            args.blkObj.addExternal_libraries(lib_name);
            args.expected_lusDT = expected_param_dt;
            [param, ~, dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
            code = arrayfun(@(i) nasa_toLustre.lustreAst.NodeCallExpr(fun_name, param{i}), ...
                (1:numel(param)), 'UniformOutput', false);
            exp_dt = expected_param_dt;
            
            %function with two arguments
        case {'rem', 'mod'}
            args.expected_lusDT = '';
            [param1, param1_dt, dim1, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
            [param2, param2_dt, dim2, extra_code_i] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2), args);
            extra_code = MatlabUtils.concat(extra_code, extra_code_i);
            params_Dt = nasa_toLustre.utils.MExpToLusDT.upperDT(param1_dt, param2_dt);
            if strcmp(params_Dt, 'int')
                fun_name = strcat(tree_ID, '_int_int');
                lib_name = strcat('LustMathLib_', fun_name);
                args.blkObj.addExternal_libraries(lib_name);
                exp_dt = 'int';
            else
                args.blkObj.addExternal_libraries('LustMathLib_simulink_math_fcn');
                fun_name = strcat(tree_ID, '_real');
                params_Dt = 'real';
                exp_dt = 'real';
            end
            
            if numel(dim1) > numel(dim2)
                dim = dim1;
            else
                dim = dim2;
            end
            % make sure parameter is converted to real
            param1 = nasa_toLustre.utils.MExpToLusDT.convertDT(args.blkObj, param1, param1_dt, params_Dt);
            param2 = nasa_toLustre.utils.MExpToLusDT.convertDT(args.blkObj, param2, param2_dt, params_Dt);
            
            % inline operands
            [param1, param2] = nasa_toLustre.utils.MExpToLusAST.inlineOperands(param1, param2, tree);
            
            code = arrayfun(@(i) nasa_toLustre.lustreAst.NodeCallExpr(fun_name, {param1{i},param2{i}}), ...
                (1:numel(param1)), 'UniformOutput', false);
        otherwise
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" is not handled in Block %s',...
                tree.ID, args.blk.Origin_path);
            throw(ME);
    end
end

