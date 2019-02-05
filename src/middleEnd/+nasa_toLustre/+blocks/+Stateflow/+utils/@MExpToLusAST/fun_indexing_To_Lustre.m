function [code, exp_dt] = fun_indexing_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow)
    import nasa_toLustre.lustreAst.*
    import nasa_toLustre.blocks.Stateflow.utils.*
    import nasa_toLustre.utils.SLX2LusUtils
    % Do not forget to update exp_dt in each switch case if needed
    exp_dt = MExpToLusDT.expression_DT(tree, data_map, inputs, isSimulink, isStateFlow);
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
                isSimulink, isStateFlow);
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
                isSimulink, isStateFlow);
            [param2, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(2),...
                parent, blk, data_map, inputs, 'real', ...
                isSimulink, isStateFlow);
            
            
            % inline operands
            [param1, param2] = MExpToLusAST.inlineOperands(param1, param2, tree);
            
            code = arrayfun(@(i) NodeCallExpr(fun_name, {param1{i},param2{i}}), ...
                (1:numel(param1)), 'UniformOutput', false);
            exp_dt = 'real';
            
        case {'abs', 'sgn'}
            expected_param_dt = exp_Dt;
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
                isSimulink, isStateFlow);
            code = arrayfun(@(i) NodeCallExpr(fun_name, param{i}), ...
                (1:numel(param)), 'UniformOutput', false);
            exp_dt = expected_param_dt;
            
        case {'ceil', 'floor', 'round', 'fabs'}
            expected_param_dt = 'real';
            if ismember(tree_ID, {'ceil', 'floor', 'round'})
                fun_name = strcat('_', tree_ID);
                lib_name = strcat('LustDTLib_', fun_name);
            elseif isequal(tree_ID, 'fabs')
                fun_name = tree_ID;
                lib_name = strcat('LustMathLib_', fun_name);
            end
            BlkObj.addExternal_libraries(lib_name);
            
            [param, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                parent, blk, data_map, inputs, expected_param_dt, ...
                isSimulink, isStateFlow);
            code = arrayfun(@(i) NodeCallExpr(fun_name, param{i}), ...
                (1:numel(param)), 'UniformOutput', false);
            exp_dt = 'real';
            
        case {'int8', 'int16', 'int32', ...
                'uint8', 'uint16', 'uint32', ...
                'double', 'single', 'boolean'}
            
            param = tree.parameters(1);
            if isequal(param.type, 'constant')
                % cast of constant
                v = eval(tree.value);
                exp_dt = SLX2LusUtils.get_lustre_dt(tree_ID);
                code = cell(numel(v), 1);
                for i=1:numel(v)
                    code{i} = SLX2LusUtils.num2LusExp(v(i), exp_dt, tree_ID);
                end
            else
                % cast of expression/variable
                [param, param_dt] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                    parent, blk, data_map, inputs, '', isSimulink, isStateFlow);
                [external_lib, conv_format] = ...
                    SLX2LusUtils.dataType_conversion(param_dt, tree_ID);
                if ~isempty(conv_format)
                    BlkObj.addExternal_libraries(external_lib);
                    code = arrayfun(@(i) ...
                        SLX2LusUtils.setArgInConvFormat(conv_format, param{i}), ...
                        (1:numel(param)), 'UniformOutput', false);
                    exp_dt = SLX2LusUtils.get_lustre_dt(tree_ID);
                else
                    % no casting needed
                    code = param;
                    exp_dt = param_dt;
                end
            end
            
            %function with two arguments
        case {'rem', 'mod'}
            [param1, param1_dt] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                parent, blk, data_map, inputs, '', ...
                isSimulink, isStateFlow);
            [param2, param2_dt] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(2),...
                parent, blk, data_map, inputs, '', ...
                isSimulink, isStateFlow);
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
            
            
        case 'hypot'
            exp_dt = 'real';
            BlkObj.addExternal_libraries('LustMathLib_lustrec_math');
            [param1, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                parent, blk, data_map, inputs, 'real', ...
                isSimulink, isStateFlow);
            [param2, ~] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(2),...
                parent, blk, data_map, inputs, 'real', ...
                isSimulink, isStateFlow);
            
            % sqrt(x*x, y*y)
            param1 = arrayfun(@(i) BinaryExpr(BinaryExpr.MULTIPLY, param1{i}, param1{i}), ...
                (1:numel(param1)), 'UniformOutput', false);
            param2 = arrayfun(@(i) BinaryExpr(BinaryExpr.MULTIPLY, param2{i}, param2{i}), ...
                (1:numel(param2)), 'UniformOutput', false);
            % inline operands
            [param1, param2] = MExpToLusAST.inlineOperands(param1, param2, tree);
            
            code = arrayfun(@(i) NodeCallExpr('sqrt', {param1{i},param2{i}}), ...
                (1:numel(param1)), 'UniformOutput', false);
            
        case {'all', 'any'}
            [x, x_dt] = MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
                parent, blk, data_map, inputs, 'bool', ...
                isSimulink, isStateFlow);
            x = MExpToLusDT.convertDT(BlkObj, x, x_dt, 'bool');
            if isequal(tree_ID, 'all')
                op = BinaryExpr.AND;
            else
                op = BinaryExpr.OR;
            end
            code{1} = BinaryExpr.BinaryMultiArgs(op, x);
            exp_dt = 'bool';
            
            
        case {'disp', 'sprintf', 'fprintf'}
            %ignore these printing functions
            code = {};
            exp_dt = '';
            
        otherwise
            code = parseOtherFunc(BlkObj, tree, ...
                parent, blk, data_map, inputs, ...
                expected_dt, isSimulink, isStateFlow);
    end
    
end



function code = parseOtherFunc(obj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow)
    global SF_GRAPHICALFUNCTIONS_MAP;
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
    if isStateFlow && data_map.isKey(tree.ID)
        %Array Access
        code = MExpToLusAST.sfArrayAccess(obj, tree, parent, blk, ...
            data_map, inputs,  expected_dt, isSimulink, isStateFlow);
        
    elseif isStateFlow && SF_GRAPHICALFUNCTIONS_MAP.isKey(tree.ID)
        %Stateflow Function
        code = SFGraphFunction(obj, tree, parent, blk, ...
            data_map, inputs, expected_dt, isSimulink, isStateFlow);
        
    elseif ~isStateFlow && isequal(tree.ID, 'u')
        %"u" refers to an input in IF, Switch and Fcn
        %blocks
        if isequal(tree.parameters(1).type, 'constant')
            %the case of u(1), u(2) ...
            input_idx = str2double(tree.parameters(1).value);
            code = inputs{1}{input_idx};
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'expression "%s" is not supported in block "%s"', ...
                tree.text, blk.Origin_path);
            throw(ME);
        end
        
    elseif ~isStateFlow &&  ~isempty(regexp(tree.ID, 'u\d+', 'match'))
        % case of u1, u2 ...
        input_number = str2double(regexp(tree.ID, 'u(\d+)', 'tokens', 'once'));
        if isequal(tree.parameters(1).type, 'constant')
            arrayIndex = str2double(tree.parameters(1).value);
            code = inputs{input_number}{arrayIndex};
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'expression "%s" is not supported in block "%s"', ...
                tree.text, blk.Origin_path);
            throw(ME);
        end
    else
        try
            % eval in base expression such as
            % A(1,1) or single(1e-18) ...
            exp = tree.text;
            [value, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, exp);
            if status
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Not found Variable "%s" in block "%s" or in workspace', ...
                    exp, blk.Origin_path);
                throw(ME);
            end
            if strcmp(expected_dt, 'real') ...
                    || isempty(expected_dt)
                code = RealExpr(value);
            elseif strcmp(expected_dt, 'bool')
                code = BooleanExpr(value);
            else
                code = IntExpr(value);
            end
        catch
            
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" is not handled in Block %s',...
                tree.ID, blk.Origin_path);
            throw(ME);
            
        end
    end
    % we need this function to return a cell.
    if ~iscell(code)
        code = {code};
    end
end





function code = SFGraphFunction(obj, tree, parent, ...
        blk, data_map, inputs, expected_dt, isSimulink, isStateFlow)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
    global SF_GRAPHICALFUNCTIONS_MAP SF_STATES_NODESAST_MAP;
    func = SF_GRAPHICALFUNCTIONS_MAP(tree.ID);
    
    if isa(tree.parameters, 'struct')
        parameters = arrayfun(@(x) x, tree.parameters, 'UniformOutput', false);
    else
        parameters = tree.parameters;
    end
    sfNodename = SF_To_LustreNode.getUniqueName(func);
    actionNodeAst = SF_STATES_NODESAST_MAP(sfNodename);
    node_inputs = actionNodeAst.getInputs();
    if isempty(parameters)
        [call, ~] = actionNodeAst.nodeCall();
        code = call;
    elseif numel(node_inputs) == numel(parameters)
        params_dt =  {};
        for i=1:numel(node_inputs)
            d = node_inputs{i};
            params_dt{end+1} = d.getDT();
        end
        args = cell(numel(parameters), 1);
        for i=1:numel(parameters)
            [args(i), ~] = ...
                MExpToLusAST.expression_To_Lustre(obj, parameters{i}, ...
                parent, blk, data_map, node_inputs, params_dt{i}, isSimulink,...
                isStateFlow);
        end
        code = NodeCallExpr(sfNodename, args);
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function "%s" expected %d parameters but got %d',...
            tree.ID, numel(node_inputs), numel(tree.parameters));
        throw(ME);
    end
    
end
