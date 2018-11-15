classdef Exp2Lus < handle
    %Exp2Lus pre-process an expression to generate valid pseudo lustre code.
    %This function will be used by If_To_Lustre, SwitchCase_To_Lustre, Fcn_To_Lustre
    % and Stateflow to parse state/transition actions.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods (Static = true)
        function [lusCode, status] = expToLustre(BlkObj, exp, parent, blk, inputs, data_map, expected_dt, isStateFlow)
            if isempty(blk)
                blk.Origin_path = 'Stateflow chart';
            end
            if ~exist('isStateFlow', 'var')
                isStateFlow = false;
            end
            status = 0;
            lusCode = '';
            if isempty(exp)
                return;
            end
            %pre-process exp
            orig_exp = exp;
            exp = strrep(orig_exp, '!=', '~=');
            exp = strrep(exp, '[', '(');
            exp = strrep(exp, ']', ')');
            %get exp IR
            try
                em2json =  cocosim.matlab2IR.EM2JSON;
                IR_string = em2json.StringToIR(exp);
                IR = json_decode(char(IR_string));
                tree = IR.statements(1);
            catch me
                status = 1;
                display_msg(sprintf('ParseError for expression "%s" in block %s', ...
                    orig_exp, blk.Origin_path), ...
                    MsgType.ERROR, 'Exp2Lus.expToLustre', '');
                display_msg(me.getReport(), MsgType.DEBUG, 'Exp2Lus.expToLustre', '');
                return;
            end
            try
                lusCode = Exp2Lus.tree2code(BlkObj, tree, parent, blk, inputs, data_map, expected_dt, isStateFlow);
            catch me
                status = 1;
                display_msg(me.getReport(), MsgType.DEBUG, 'Exp2Lus.expToLustre', '');
                if strcmp(me.identifier, 'COCOSIM:TREE2CODE')
                    display_msg(sprintf('ParseError for expression "%s" in block %s', ...
                        orig_exp, blk.Origin_path), ...
                        MsgType.ERROR, 'Exp2Lus.expToLustre', '');
                    
                    return;
                end
            end
            
        end
        function code = tree2code(obj, tree, parent, blk, inputs, data_map, expected_dt, isStateFlow)
            %this function is extended to be used by If-Block,
            %SwitchCase and Fcn blocks. Also it is used by Stateflow
            %actions
            if ~exist('isStateFlow', 'var')
                isStateFlow = false;
            end
            code = '';
            if isempty(tree)
                return;
            end
            
            tree_type = tree.type;
            if isequal(tree_type, 'ID')
                code = Exp2Lus.ID2code(obj, tree.name, parent, blk, inputs, ...
                    data_map, expected_dt, isStateFlow);
                return;
            end
            if isequal(tree_type, 'constant')
                code = Exp2Lus.constant2code(tree.value, expected_dt);
                return;
            end
            tree_dt = Exp2Lus.treeDT(tree, inputs, data_map, expected_dt, isStateFlow);
            switch tree_type
                case {'plus_minus', 'mtimes', 'mrdivide', ...
                        'relopGL', 'relopEQ_NE', ...
                        'relopAND', 'relopelAND', 'relopOR', 'relopelOR'}
                    operands_dt = tree_dt;
                    if ismember(tree_type, {'relopGL', 'relopEQ_NE'})
                        left_dt = Exp2Lus.treeDT(tree.leftExp, inputs, data_map, expected_dt, isStateFlow);
                        right_dt = Exp2Lus.treeDT(tree.rightExp, inputs, data_map, expected_dt, isStateFlow);
                        operands_dt = Exp2Lus.upperDT(left_dt, right_dt, expected_dt);
                    end
                    if isequal(tree_type, 'plus_minus')
                        op = tree.operator;
                    elseif isequal(tree_type, 'mtimes')
                        op = BinaryExpr.MULTIPLY;
                    elseif isequal(tree_type, 'mrdivide')
                        op = BinaryExpr.DIVIDE;
                    elseif isequal(tree_type, 'relopGL')
                        op = tree.operator;
                        
                    elseif isequal(tree_type, 'relopEQ_NE')
                        if isequal(tree.operator, '==')
                            op = BinaryExpr.EQ;
                        else
                            op = BinaryExpr.NEQ;
                        end
                        
                    elseif ismember(tree_type, {'relopAND', 'relopelAND'})
                        %TODO relopelAND is bitwise AND
                        op = BinaryExpr.AND;
                        
                    elseif ismember(tree_type, {'relopOR', 'relopelOR'})
                        %TODO relopelOR is bitwise OR
                        op = BinaryExpr.OR;
                        
                    end
                    
                    code = BinaryExpr(op, ...
                        Exp2Lus.tree2code(obj, tree.leftExp, parent, blk, inputs, data_map, operands_dt, isStateFlow), ...
                        Exp2Lus.tree2code(obj, tree.rightExp, parent, blk, inputs, data_map, operands_dt, isStateFlow), ...
                        false);
                    
                case 'unaryExpression'
                    if isequal(tree.operator, '~') || isequal(tree.operator, '!')
                        op = UnaryExpr.NOT;
                    elseif isequal(tree.operator, '-')
                        op = UnaryExpr.NEG;
                    else
                        op = tree.operator;
                    end
                    
                    code = UnaryExpr(op, ...
                        Exp2Lus.tree2code(obj, tree.rightExp, parent, blk, inputs, data_map, tree_dt, isStateFlow), ...
                        false);
                    
                case 'parenthesedExpression'
                    tree_dt = expected_dt;
                    code = ParenthesesExpr(...
                        Exp2Lus.tree2code(obj, tree.expression, parent, blk, inputs, data_map, tree_dt, isStateFlow));
                    
                case 'mpower'
                    tree_dt = 'real';
                    obj.addExternal_libraries('LustMathLib_lustrec_math');
                    code = NodeCallExpr('pow', ...
                        {Exp2Lus.tree2code(obj, tree.leftExp, parent, blk, inputs, data_map, tree_dt, isStateFlow), ...
                        Exp2Lus.tree2code(obj, tree.rightExp, parent, blk, inputs, data_map, tree_dt, isStateFlow)});
                                        
                case 'assignment'
                    tree_dt = expected_dt;%no need for casting type.
                    assignment_dt = Exp2Lus.treeDT(tree, inputs, data_map, expected_dt, isStateFlow);
                    code = LustreEq(...
                        Exp2Lus.tree2code(obj, tree.leftExp, parent, blk, inputs, data_map, assignment_dt, isStateFlow), ...
                        Exp2Lus.tree2code(obj, tree.rightExp, parent, blk, inputs, data_map, assignment_dt, isStateFlow) ...
                        );
                    
                case 'fun_indexing'
                    tree_ID = tree.ID;
                    switch tree_ID
                        %functions with one argument
                        case {'sqrt', 'exp', 'log', 'log10',...
                                'sin','cos','tan',...
                                'asin','acos','atan', ...
                                'sinh','cosh', ...
                                'abs', 'sgn', ...
                                'ceil', 'floor'}
                            tree_dt = Exp2Lus.treeDT(tree, inputs, data_map, expected_dt, isStateFlow);
                            if isequal(tree_ID, 'abs') ...
                                    || isequal(tree_ID, 'sgn')
                                fun_name = strcat(tree_ID, '_', tree_dt);
                                lib_name = strcat('LustMathLib_', fun_name);
                                obj.addExternal_libraries(lib_name);
                                
                            elseif ismember(tree_ID, ...
                                    {'sqrt', 'exp', 'log', 'log10',...
                                    'sin','cos','tan',...
                                    'asin','acos','atan', ...
                                    'sinh','cosh'})
                                
                                fun_name = tree_ID;
                                obj.addExternal_libraries('LustMathLib_lustrec_math');
                                
                            elseif isequal(tree_ID, 'ceil') ...
                                    || isequal(tree_ID, 'floor')
                                
                                fun_name = strcat('_', tree_ID);
                                lib_name = strcat('LustDTLib_', fun_name);
                                obj.addExternal_libraries(lib_name);
                                
                            else
                                fun_name = tree_ID;
                            end
                            code = NodeCallExpr(fun_name,...
                                Exp2Lus.tree2code(obj, tree.parameters(1), parent, blk, inputs, data_map, tree_dt, isStateFlow));
                                                        
                            %function with two arguments
                        case {'rem', 'atan2', 'power'}
                            tree_dt = Exp2Lus.treeDT(tree, inputs, data_map, expected_dt, isStateFlow);
                            if isequal(tree_ID, 'atan2') ...
                                    || isequal(tree_ID, 'power')
                                obj.addExternal_libraries('LustMathLib_lustrec_math');
                                if isequal(tree_ID, 'power')
                                    fun_name = 'pow';
                                else
                                    fun_name = tree_ID;
                                end
                            elseif isequal(tree_ID, 'rem')
                                if isequal(expected_dt, 'int')
                                    fun_name = 'rem_int_int';
                                    lib_name = strcat('LustMathLib_', fun_name);
                                    obj.addExternal_libraries(lib_name);
                                else
                                    obj.addExternal_libraries('LustMathLib_simulink_math_fcn');
                                    fun_name = 'rem_real';
                                end
                            else
                                fun_name = tree_ID;
                            end
                            
                            code = NodeCallExpr(fun_name, ...
                                {Exp2Lus.tree2code(obj, tree.parameters(1), parent, blk, inputs, data_map, tree_dt, isStateFlow), ...
                                Exp2Lus.tree2code(obj, tree.parameters(2), parent, blk, inputs, data_map, tree_dt, isStateFlow)});
                            
                            
                        case 'hypot'
                            
                            tree_dt = 'real';
                            obj.addExternal_libraries('LustMathLib_lustrec_math');
                            arg1 = Exp2Lus.tree2code(obj, tree.parameters(1), ...
                                parent, blk, inputs, data_map, tree_dt, isStateFlow);
                            arg1 = BinaryExpr(BinaryExpr.MULTIPLY, arg1, arg1);
                            arg2 = Exp2Lus.tree2code(obj, tree.parameters(2),...
                                parent, blk, inputs, data_map, tree_dt, isStateFlow);
                            arg2 = BinaryExpr(BinaryExpr.MULTIPLY, arg2, arg2);
                            
                            
                            code = NodeCallExpr('sqrt', {arg1, arg2});
                        otherwise
                            code = Exp2Lus.parseOtherFunc(obj, tree, ...
                                parent, blk, inputs, data_map, ...
                                expected_dt, isStateFlow);
                    end
                otherwise
                    if isStateFlow
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Tree type "%s" not handled in Stateflow',...
                            tree_type);
                    else
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Tree type "%s" not handled in Block %s',...
                            tree_type, blk.Origin_path);
                    end
                    throw(ME);
            end
            % convert tree DT to what is expected.
            code = Exp2Lus.convertDT(obj, code, tree_dt, expected_dt);
        end
        
        function code = constant2code(v, expected_dt)
            if strcmp(expected_dt, 'real') || isempty(expected_dt)
                code = RealExpr(str2double(v));
            elseif strcmp(expected_dt, 'bool')
                code = BooleanExpr(str2double(v));
            else
                %tree might be 1 or 3e5
                code = IntExpr(str2double(v));
            end
        end
        function code = ID2code(obj, id, parent, blk, inputs, data_map, expected_dt, isStateFlow)
            % the case of final term in a tree
            if strcmp(id, 'true') || strcmp(id, 'false')
                code = BooleanExpr(id);
            elseif ~isStateFlow && strcmp(id, 'u')
                %the case of u with no index
                code = inputs{1}{1};
            elseif ~isStateFlow && ~isempty(regexp(id, 'u\d+', 'match'))
                input_idx = regexp(id, 'u(\d+)', 'tokens', 'once');
                code = inputs{str2double(input_idx)}{1};
            elseif ~isStateFlow
                %check for variables in workspace
                [value, ~, status] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, id);
                if status
                    ME = MException('COCOSIM:TREE2CODE', ...
                        'Not found Variable "%s" in block "%s"', ...
                        id, blk.Origin_path);
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
            elseif isKey(data_map, id)
                %We assume Stateflow does not support variables
                %from workspace to be called within the chart
                %actions.
                %We keep it as VarID
                if isfield(data_map(id), 'LusDatatype')
                    dt = data_map(id).LusDatatype;
                else
                    dt = data_map(id);
                end
                code = Exp2Lus.convertDT(obj, VarIdExpr(id), dt, expected_dt);
            else
                %code = VarIdExpr(var_name);
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Not found Variable "%s" in block "%s"', ...
                    id, blk.Origin_path);
                throw(ME);
            end
        end
        function code = parseOtherFunc(obj, tree, parent, blk, inputs, data_map, expected_dt, isStateFlow)
            if ~isStateFlow && isequal(tree.ID, 'u')
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
                    if isStateFlow
                        %TODO: handling Stateflow functions will
                        %be in a seperate function.
                        args = cell(numel(tree.parameters), 1);
                        for i=1:numel(tree.parameters)
                            args{i} = ...
                                Exp2Lus.tree2code(obj, tree.parameters(i), ...
                                parent, blk, inputs, data_map, expected_dt, isStateFlow);
                        end
                        code = NodeCallExpr(tree.ID, args);
                    else
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Function "%s" is not handled in Block %s',...
                            tree{2}, blk.Origin_path);
                        throw(ME);
                    end
                end
            end
        end
        
        function code = convertDT(obj, code, input_dt, output_dt)
            if isempty(input_dt) || isempty(output_dt) || isequal(input_dt, output_dt)
                return;
            end
            conv = strcat(input_dt, '_to_', output_dt);
            obj.addExternal_libraries(strcat('LustDTLib_', conv));
            code = NodeCallExpr(conv, code);
        end
        function dt = upperDT(left_dt, right_dt, expected_dt)
            if isempty(left_dt) && isempty(right_dt) 
                dt = expected_dt;
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
        
        function dt = treeDT(tree, inputs, data_map, expected_dt, isStateFlow)
            %this function is extended to be used by If-Block,
            %SwitchCase and Fcn blocks. Also it is used by Stateflow
            %actions
            dt = '';
            if isempty(tree)
                return;
            end
            tree_type = tree.type;
            if isequal(tree_type, 'ID')
                dt = Exp2Lus.ID2DT(tree.name, inputs, data_map, isStateFlow);
                return;
            end
            if isequal(tree_type, 'constant')
                if isequal(tree.dataType, 'Integer')
                    dt = 'int';
                else
                    dt = 'real';
                end
                return;
            end
            switch tree_type
                case {'relopAND', 'relopelAND',...
                        'relopOR', 'relopelOR', ...
                        'relopGL', 'relopEQ_NE'}
                    dt = 'bool';
                case {'plus_minus', 'mtimes', 'mrdivide'}
                    left_dt = Exp2Lus.treeDT(tree.leftExp, inputs, data_map, expected_dt, isStateFlow);
                    right_dt = Exp2Lus.treeDT(tree.rightExp, inputs, data_map, expected_dt, isStateFlow);
                    dt = Exp2Lus.upperDT(left_dt, right_dt, expected_dt);
                    
                case 'unaryExpression'
                    if isequal(tree.operator, '~') || isequal(tree.operator, '!')
                        dt = 'bool';
                    else
                        dt = Exp2Lus.treeDT(tree.rightExp, inputs, data_map, expected_dt, isStateFlow);
                    end
                case 'parenthesedExpression'
                    dt = Exp2Lus.treeDT(tree.expression, inputs, data_map, expected_dt, isStateFlow);
                    
                case 'mpower'
                    dt = 'real';
                    
                case 'assignment'
                    dt = Exp2Lus.treeDT(tree.leftExp, inputs, data_map, expected_dt, isStateFlow);
                    
                case 'fun_indexing'
                    tree_ID = tree.ID;
                    switch tree_ID
                        case {'abs', 'sgn'}
                            dt = Exp2Lus.treeDT(tree.parameters(1), inputs, data_map, expected_dt, isStateFlow);
                        case 'rem'
                            param1 = Exp2Lus.treeDT(tree.parameters(1), inputs, data_map, expected_dt, isStateFlow);
                            param2 = Exp2Lus.treeDT(tree.parameters(2), inputs, data_map, expected_dt, isStateFlow);
                            dt = Exp2Lus.upperDT(param1, param2, expected_dt);
                        case {'sqrt', 'exp', 'log', 'log10',...
                                'sin','cos','tan',...
                                'asin','acos','atan','atan2', 'power', ...
                                'sinh','cosh', ...
                                'ceil', 'floor', 'hypot'}
                            dt = 'real';                        
                        otherwise
                            dt = Exp2Lus.OtherFuncDT(tree, inputs, data_map, expected_dt, isStateFlow);
                    end
                otherwise
                    dt = expected_dt;
            end
            
        end
        
        function dt = OtherFuncDT(tree, inputs, data_map, expected_dt, isStateFlow)
            dt = expected_dt;
            if ~isStateFlow && isequal(tree.ID, 'u')
                %"u" refers to an input in IF, Switch and Fcn
                %blocks
                if isequal(tree.parameters(1).type, 'constant')
                    %the case of u(1), u(2) ...
                    input_idx = str2double(tree.parameters(1).value);
                    dt = Exp2Lus.getVarDT(data_map, ...
                        inputs{1}{input_idx}.getId());
                    return;
                end
                
            elseif ~isStateFlow &&  ~isempty(regexp(tree.ID, 'u\d+', 'match'))
                % case of u1, u2 ...
                input_number = str2double(regexp(tree.ID, 'u(\d+)', 'tokens', 'once'));
                if isequal(tree.parameters(1).type, 'constant')
                    arrayIndex = str2double(tree.parameters(1).value);
                    dt = Exp2Lus.getVarDT(data_map, ...
                        inputs{input_number}{arrayIndex}.getId());
                    return;
                end
            else
                %TODO Stateflow functions
            end
        end
        
        
        function dt = ID2DT(id, inputs, data_map, isStateFlow)
            % the case of final term in a tree
            if strcmp(id, 'true') || strcmp(id, 'false')
                dt = 'bool';
                
            elseif ~isStateFlow && strcmp(id, 'u')
                %the case of u with no index
                dt = Exp2Lus.getVarDT(data_map, inputs{1}{1}.getId());
                
            elseif ~isStateFlow && ~isempty(regexp(id, 'u\d+', 'match'))
                input_idx = regexp(id, 'u(\d+)', 'tokens', 'once');
                dt = Exp2Lus.getVarDT(data_map, ...
                    inputs{str2double(input_idx)}{1}.getId());
                
            elseif isKey(data_map, id)
                if isfield(data_map(id), 'LusDatatype')
                    dt = data_map(id).LusDatatype;
                else
                    dt = data_map(id);
                end
            else
                dt = '';
            end
        end
        
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
    end
end

