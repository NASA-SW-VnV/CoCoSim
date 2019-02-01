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
            global SF_GRAPHICALFUNCTIONS_MAP SF_STATES_NODESAST_MAP;
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            if ~exist('isStateFlow', 'var')
                isStateFlow = false;
            end
            if isempty(blk)
                if isStateFlow
                    blk.Origin_path = 'Stateflow chart';
                else
                    blk.Origin_path = '';
                end
            end
            status = 0;
            lusCode = {};
            if isempty(exp)
                return;
            end
            %pre-process exp
            orig_exp = exp;
            exp = strrep(orig_exp, '!=', '~=');
            % adapt C access array u[1] to Matlab syntax u(1)
            exp = regexprep(exp, '(\w)\[([^\[\]])+\]', '$1($2)');
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
                    MsgType.ERROR, 'nasa_toLustre.utils.Exp2Lus.expToLustre', '');
                display_msg(me.getReport(), MsgType.DEBUG, 'nasa_toLustre.utils.Exp2Lus.expToLustre', '');
                return;
            end
            try
                
                lusCode = nasa_toLustre.utils.Exp2Lus.tree2code(BlkObj, tree, parent, blk, inputs, data_map, expected_dt, isStateFlow);
                % transform Stateflow Function call with no outputs to an equation
                if isStateFlow && ~isempty(tree)
                    if iscell(tree) && numel(tree) == 1
                        tree = tree{1};
                    end
                    if isfield(tree, 'type') && ...
                            isequal(tree.type, 'fun_indexing') &&...
                            isKey(SF_GRAPHICALFUNCTIONS_MAP, tree.ID)
                        func = SF_GRAPHICALFUNCTIONS_MAP(tree.ID);
                        sfNodename = SF_To_LustreNode.getUniqueName(func);
                        actionNodeAst = SF_STATES_NODESAST_MAP(sfNodename);
                        [~, oututs_Ids] = actionNodeAst.nodeCall();
                        lusCode{1} = LustreEq(oututs_Ids,...
                            lusCode{1});
                    end
                end
            catch me
                status = 1;
                
                if strcmp(me.identifier, 'COCOSIM:TREE2CODE')
                    display_msg(me.message, MsgType.ERROR, 'nasa_toLustre.utils.Exp2Lus.expToLustre', '')
                    display_msg(sprintf('ParseError for expression "%s" in block %s', ...
                        orig_exp, blk.Origin_path), ...
                        MsgType.ERROR, 'nasa_toLustre.utils.Exp2Lus.expToLustre', '');
                    return;
                else
                    display_msg(me.getReport(), MsgType.DEBUG, 'nasa_toLustre.utils.Exp2Lus.expToLustre', '');
                end
            end
            
        end
        function code = tree2code(obj, tree, parent, blk, inputs, data_map, expected_dt, isStateFlow)
            %this function is extended to be used by If-Block,
            %SwitchCase and Fcn blocks. Also it is used by Stateflow
            %actions
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            if nargin < 8
                isStateFlow = false;
            end
            % we assume this function returns cell.
            code = {};
            if isempty(tree)
                return;
            end
            if iscell(tree) && numel(tree) == 1
                tree = tree{1};
            end
            tree_type = tree.type;
            if isequal(tree_type, 'ID')
                code = nasa_toLustre.utils.Exp2Lus.ID2code(obj, tree.name, parent, blk, inputs, ...
                    data_map, expected_dt, isStateFlow);
                return;
            end
            if isequal(tree_type, 'constant')
                code = nasa_toLustre.utils.Exp2Lus.constant2code(tree.value, expected_dt);
                return;
            end
            tree_dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree, inputs, data_map, expected_dt, isStateFlow);
            switch tree_type
                case {'plus_minus', 'mtimes', 'times', 'mrdivide', 'rdivide'...
                        'relopGL', 'relopEQ_NE', ...
                        'relopAND', 'relopelAND', 'relopOR', 'relopelOR'}
                    operands_dt = tree_dt;
                    if ismember(tree_type, {'relopGL', 'relopEQ_NE'})
                        left_dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree.leftExp, inputs, data_map, expected_dt, isStateFlow);
                        right_dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree.rightExp, inputs, data_map, expected_dt, isStateFlow);
                        operands_dt = nasa_toLustre.utils.Exp2Lus.upperDT(left_dt, right_dt, expected_dt);
                    end
                    if isequal(tree_type, 'plus_minus')
                        op = tree.operator;
                    elseif isequal(tree_type, 'mtimes') ...
                            || isequal(tree_type, 'times')
                        op = BinaryExpr.MULTIPLY;
                    elseif isequal(tree_type, 'mrdivide')...
                            || isequal(tree_type, 'rdivide')
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
                    left = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.leftExp, parent,...
                        blk, inputs, data_map, operands_dt, isStateFlow);
                    right = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.rightExp, parent,...
                        blk, inputs, data_map, operands_dt, isStateFlow);
                    if numel(left) == 1 && numel(right) == 1
                        code{1} = BinaryExpr(op, left{1}, right{1}, false);
                    else
                        if numel(left) == 1
                            left = arrayfun(@(x) left{1}, (1:numel(right)), 'UniformOutput', false);
                        elseif numel(right) == 1
                            right = arrayfun(@(x) right{1}, (1:numel(left)), 'UniformOutput', false);
                        elseif ismember(tree_type, {'mtimes',  'mrdivide'})
                            ME = MException('COCOSIM:TREE2CODE', ...
                                'Expression "%s" has matrix product/division. Is not currently supported.',...
                                tree.text);
                            throw(ME);
                        end
                        if numel(left) ~= numel(right)
                            ME = MException('COCOSIM:TREE2CODE', ...
                                'Expression "%s" has incompatible dimensions. Left width is %d where the right width is %d',...
                                tree.text, numel(left), numel(right));
                            throw(ME);
                        end
                        code = arrayfun(@(i) BinaryExpr(op, left{i}, right{i}, false), ...
                            (1:numel(left)), 'UniformOutput', false);
                    end
                    
                case 'unaryExpression'
                    if isequal(tree.operator, '~') || isequal(tree.operator, '!')
                        op = UnaryExpr.NOT;
                    elseif isequal(tree.operator, '-')
                        op = UnaryExpr.NEG;
                    else
                        op = tree.operator;
                    end
                    right = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.rightExp, parent,...
                        blk, inputs, data_map, tree_dt, isStateFlow);
                    code = arrayfun(@(i) UnaryExpr(op, right{i}, false), ...
                        (1:numel(right)), 'UniformOutput', false);
                    
                case 'parenthesedExpression'
                    tree_dt = expected_dt;
                    exp = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.expression, parent,...
                        blk, inputs, data_map, tree_dt, isStateFlow);
                    code = arrayfun(@(i) ParenthesesExpr(exp{i}), ...
                        (1:numel(exp)), 'UniformOutput', false);
                case {'mpower', 'power'}
                    tree_dt = 'real';
                    obj.addExternal_libraries('LustMathLib_lustrec_math');
                    left = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.leftExp, parent, blk, ...
                        inputs, data_map, tree_dt, isStateFlow);
                    right= nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.rightExp, parent, blk,...
                        inputs, data_map, tree_dt, isStateFlow);
                    if numel(left) > 1 && isequal(tree_type, 'mpower')
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Expression "%s" has a power of matrix is not supported.',...
                            tree.text);
                        throw(ME);
                    end
                    if numel(right) == 1
                        right = arrayfun(@(x) right{1}, (1:numel(left)), 'UniformOutput', false);
                    end
                    code = arrayfun(@(i) NodeCallExpr('pow', {left{i},right{i}}), ...
                        (1:numel(left)), 'UniformOutput', false);
                                        
                case 'assignment'
                    tree_dt = expected_dt;%no need for casting type.
                    assignment_dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree, inputs, data_map,...
                        expected_dt, isStateFlow);
                    if isequal(tree.leftExp.type, 'matrix')
                        elts = tree.leftExp.rows{1};
                        args = cell(numel(elts), 1);
                        if ischar(expected_dt)
                            left_dt = arrayfun(@(i) expected_dt, ...
                                (1:numel(elts)), 'UniformOutput', false);
                        elseif iscell(expected_dt) && numel(expected_dt) < numel(elts)
                            left_dt = arrayfun(@(i) expected_dt{1}, ...
                                (1:numel(elts)), 'UniformOutput', false);
                        end
                        for i=1:numel(elts)
                            args(i) = ...
                                nasa_toLustre.utils.Exp2Lus.tree2code(obj, elts(i), ...
                                parent, blk, inputs, data_map, left_dt{i},...
                                isStateFlow);
                        end
                        left{1} = TupleExpr(args);
                    else
                        if isequal(tree.leftExp.type, 'fun_indexing') ...
                                && ~isequal(tree.leftExp.parameters.type, 'constant')
                            ME = MException('COCOSIM:TREE2CODE', ...
                                'Array index on the left hand of the expression "%s" should be a constant.',...
                                tree.text);
                            throw(ME);
                        end
                        left = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.leftExp, ...
                            parent, blk, inputs, data_map, assignment_dt,...
                            isStateFlow);
                    end
                    right = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.rightExp, parent, blk,...
                        inputs, data_map, assignment_dt, isStateFlow);
                    if numel(left) ~= numel(right)
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Assignement "%s" has incompatible dimensions. Left width is %d where the right width is %d',...
                            tree.text, numel(left), numel(right));
                        throw(ME);
                    end
                    for i=1:numel(left)
                        code{i} = LustreEq(left{i}, right{i});
                    end
                    
                case 'fun_indexing'
                    tree_ID = tree.ID;
                    switch tree_ID
                        %functions with one argument
                        case {'sqrt', 'exp', 'log', 'log10',...
                                'sin','cos','tan',...
                                'asin','acos','atan', ...
                                'sinh','cosh', ...
                                'abs', 'sgn', ...
                                'ceil', 'floor', ...
                                'int8', 'int16', 'int32', ...
                                'uint8', 'uint16', 'uint32', ...
                                'double', 'single', 'boolean'}
                            conv_format = {};
                            isConversion = false;
                            tree_dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree, inputs, data_map, expected_dt, isStateFlow);
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
                            elseif ismember(tree_ID, ...
                                    {'int8', 'int16', 'int32', ...
                                    'uint8', 'uint16', 'uint32', ...
                                    'double', 'single', 'boolean'})
                                tree_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(tree_ID);
                                param = tree.parameters(1);
                                if isequal(param.type, 'constant')
                                    v = eval(tree.text);
                                    if ismember(tree_ID, ...
                                            {'int8', 'int16', 'int32', ...
                                            'uint8', 'uint16', 'uint32'})
                                        code{1} = IntExpr(v);
                                    elseif ismember(tree_ID,{'double', 'single'})
                                        code{1} = RealExpr(v);
                                    else
                                        code{1} = BooleanExpr(v);
                                    end
                                    return;
                                else
                                    param_dt = nasa_toLustre.utils.Exp2Lus.treeDT(param, ...
                                        inputs, data_map, '', isStateFlow);
                                    [external_lib, conv_format] = ...
                                       nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(param_dt, tree_ID);
                                    if ~isempty(conv_format)
                                        obj.addExternal_libraries(external_lib);
                                        isConversion = true;
                                    else
                                        fun_name = tree_ID;
                                    end
                                end
                            else
                                fun_name = tree_ID;
                            end
                            x = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.parameters(1),...
                                parent, blk, inputs, data_map, tree_dt, ...
                                isStateFlow);
                            if isConversion
                                code = arrayfun(@(i)nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x{i}), ...
                                    (1:numel(x)), 'UniformOutput', false);
                            else
                                code = arrayfun(@(i) NodeCallExpr(fun_name, x{i}), ...
                                    (1:numel(x)), 'UniformOutput', false);
                            end
                            %function with two arguments
                        case {'rem', 'atan2', 'power'}
                            tree_dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree, inputs, data_map, expected_dt, isStateFlow);
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
                            left = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.parameters(1), ...
                                parent, blk, inputs, data_map, tree_dt, isStateFlow);
                            right = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.parameters(2), ...
                                parent, blk, inputs, data_map, tree_dt, isStateFlow);
                            if numel(left) ~= numel(right)
                                if numel(right) == 1
                                    right = arrayfun(@(x) right{1}, ...
                                        (1:numel(left)), 'UniformOutput', false);
                                elseif numel(left) == 1
                                    left = arrayfun(@(x) left{1}, ...
                                        (1:numel(right)), 'UniformOutput', false);
                                else
                                     ME = MException('COCOSIM:TREE2CODE', ...
                                         'Expression "%s" has incompatible dimensions. First parameter width is %d where the second parameter width is %d',...
                                         tree.text, numel(left), numel(right));
                                     throw(ME);
                                end
                            end
                            code = arrayfun(@(i) NodeCallExpr(fun_name, {left{i},right{i}}), ...
                                (1:numel(left)), 'UniformOutput', false);
                            
                        case 'hypot'
                            
                            tree_dt = 'real';
                            obj.addExternal_libraries('LustMathLib_lustrec_math');
                            arg1 = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.parameters(1), ...
                                parent, blk, inputs, data_map, tree_dt, isStateFlow);
                            
                            arg2 = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.parameters(2),...
                                parent, blk, inputs, data_map, tree_dt, isStateFlow);
                            
                            arg1 = arrayfun(@(i) BinaryExpr(BinaryExpr.MULTIPLY, arg1{i}, arg1{i}), ...
                                (1:numel(arg1)), 'UniformOutput', false);
                            arg2 = arrayfun(@(i) BinaryExpr(BinaryExpr.MULTIPLY, arg2{i}, arg2{i}), ...
                                (1:numel(arg2)), 'UniformOutput', false);
                            
                            if numel(arg1) ~= numel(arg2)
                                if numel(arg2) == 1
                                    arg2 = arrayfun(@(x) arg2{1}, ...
                                        (1:numel(arg1)), 'UniformOutput', false);
                                elseif numel(arg1) == 1
                                    arg1 = arrayfun(@(x) arg1{1}, ...
                                        (1:numel(arg2)), 'UniformOutput', false);
                                else
                                     ME = MException('COCOSIM:TREE2CODE', ...
                                         'Expression "%s" has incompatible dimensions. First parameter width is %d where the second parameter width is %d',...
                                         tree.text, numel(arg1), numel(arg2));
                                     throw(ME);
                                end
                            end
                            code = arrayfun(@(i) NodeCallExpr('sqrt', {arg1{i},arg2{i}}), ...
                                (1:numel(arg1)), 'UniformOutput', false);
                        case {'all', 'any'}
                            x = nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.parameters(1),...
                                parent, blk, inputs, data_map, 'bool', ...
                                isStateFlow);
                            if isequal(tree_ID, 'all')
                                op = BinaryExpr.AND;
                            else
                                op = BinaryExpr.OR;
                            end
                            code{1} = BinaryExpr.BinaryMultiArgs(op, x);
                        case {'disp', 'sprintf', 'fprintf'}
                            %ignore these printing functions
                            code = {};
                            
                        otherwise
                            code = nasa_toLustre.utils.Exp2Lus.parseOtherFunc(obj, tree, ...
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
            code = nasa_toLustre.utils.Exp2Lus.convertDT(obj, code, tree_dt, expected_dt);
        end
        
        
        %%
        function code = constant2code(v, expected_dt)
            import nasa_toLustre.lustreAst.*
            if strcmp(expected_dt, 'real') || isempty(expected_dt)
                code{1} = RealExpr(str2double(v));
            elseif strcmp(expected_dt, 'bool')
                code{1} = BooleanExpr(str2double(v));
            else
                %tree might be 1 or 3e5
                code{1} = IntExpr(str2double(v));
            end
        end
        
        %%
        function code = ID2code(obj, id, parent, blk, inputs, data_map, expected_dt, isStateFlow)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            % the case of final term in a tree
            if ~isStateFlow && ~isempty(regexp(id, 'u\d+', 'match'))
                input_idx = regexp(id, 'u(\d+)', 'tokens', 'once');
                try id = inputs{str2double(input_idx)}{1}.getId();catch, end
            elseif ~isStateFlow && strcmp(id, 'u')
                %the case of u with no index
                try id = inputs{1}{1}.getId();catch, end
            end
            if strcmp(id, 'true') || strcmp(id, 'false')
                code = BooleanExpr(id);
            elseif isKey(data_map, id)
                %We assume Stateflow does not support variables
                %from workspace to be called within the chart
                %actions.
                %We keep it as VarID
                d = data_map(id);
                if isfield(d, 'LusDatatype')
                    dt = d.LusDatatype;
                else
                    dt = d;
                end
                if ~isStateFlow
                    code = nasa_toLustre.utils.Exp2Lus.convertDT(obj, VarIdExpr(id), dt, expected_dt);
                else
                    names = SF_To_LustreNode.getDataName(d);
                    for i=1:numel(names)
                        code{i} = nasa_toLustre.utils.Exp2Lus.convertDT(obj, ...
                            VarIdExpr(names{i}), dt, expected_dt);
                    end
                    
                end
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
            else
                %code = VarIdExpr(var_name);
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Not found Variable "%s" in block "%s"', ...
                    id, blk.Origin_path);
                throw(ME);
            end
            % we need this function to return a cell.
            if ~iscell(code)
                code = {code};
            end
        end
        %% Functions, Array Access, SF Functions
        function code = parseOtherFunc(obj, tree, parent, blk, inputs, data_map, expected_dt, isStateFlow)
            global SF_GRAPHICALFUNCTIONS_MAP;
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            if isStateFlow && data_map.isKey(tree.ID)
                %Array Access
                code = nasa_toLustre.utils.Exp2Lus.SFArrayAccess(obj, tree, parent, blk, ...
                    inputs, data_map, expected_dt, isStateFlow);
                
            elseif isStateFlow && SF_GRAPHICALFUNCTIONS_MAP.isKey(tree.ID)
                %Stateflow Function
                code = nasa_toLustre.utils.Exp2Lus.SFGraphFunction(obj, tree, parent, blk, ...
                    inputs, data_map, expected_dt, isStateFlow);
                
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
        function code = SFArrayAccess(obj, tree, parent, blk, inputs, data_map, expected_dt, isStateFlow)
            %Array access
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            d = data_map(tree.ID);
            if isfield(d, 'CompiledSize')
                CompiledSize = str2num(d.CompiledSize);
            elseif isfield(d, 'ArraySize')
                CompiledSize = str2num(d.ArraySize);
            else
                CompiledSize = -1;
            end
            if CompiledSize == -1
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Data "%s" has unknown ArraySize',...
                    tree.ID);
                throw(ME);
            end
            if numel(CompiledSize) < numel(tree.parameters)
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Data Access "%s" expected %d parameters but got %d',...
                    tree.text, numel(CompiledSize), numel(tree.parameters));
                throw(ME);
            end
            params_dt = 'int';
            namesAst = nasa_toLustre.utils.Exp2Lus.ID2code(obj, tree.ID, parent, blk, inputs, ...
                data_map, expected_dt, isStateFlow);
                    
            if numel(tree.parameters) == 1
                %Vector Access
                if iscell(tree.parameters)
                    param = tree.parameters{1};
                else
                    param = tree.parameters;
                end
                param_type = param.type;
                if isequal(param_type, 'constant')
                    value = str2num(param.value);
                    
                    if iscell(namesAst) && numel(namesAst) >= value
                        code = namesAst{value};
                    else
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'ParseError of "%s"',...
                            tree.text);
                        throw(ME);
                    end
                else
                    arg = ...
                        nasa_toLustre.utils.Exp2Lus.tree2code(obj, tree.parameters, ...
                        parent, blk, inputs, data_map, params_dt,...
                        isStateFlow);
                    for ardIdx=1:numel(arg)
                        n = numel(namesAst);
                        conds = cell(n-1, 1);
                        thens = cell(n, 1);
                        for i=1:n-1
                            conds{i} = BinaryExpr(BinaryExpr.EQ, arg{ardIdx}, IntExpr(i));
                            thens{i} = namesAst{i};
                        end
                        thens{n} = namesAst{n};
                        code{ardIdx} = ParenthesesExpr(IteExpr.nestedIteExpr(conds, thens));
                    end
                end
            else
                %multi-dimension access
                if isa(tree.parameters, 'struct')
                    parameters = arrayfun(@(x) x, tree.parameters, 'UniformOutput', false);
                    params_type = arrayfun(@(x) x.type, tree.parameters, 'UniformOutput', false);
                else
                    parameters = tree.parameters;
                    params_type = cellfun(@(x) x.type, tree.parameters, 'UniformOutput', false);
                end
                isConstant = all(strcmp(params_type, 'constant'));
                if isConstant
                    %[n,m,l] = size(M)
                    %idx = i + (j-1) * n + (k-1) * n * m
                    idx = str2num(parameters{1}.value);
                    for i=2:numel(parameters)
                        v = str2num(parameters{i}.value);
                        idx = idx + (v - 1) * prod(CompiledSize(1:i-1));
                    end
                    if iscell(namesAst) && numel(namesAst) >= idx
                        code = namesAst{idx};
                    else
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'ParseError of "%s"',...
                            tree.text);
                        throw(ME);
                    end
                else
                    args = cell(numel(parameters), 1);
                    for i=1:numel(parameters)
                        args(i) = ...
                            nasa_toLustre.utils.Exp2Lus.tree2code(obj, parameters{i}, ...
                            parent, blk, inputs, data_map, params_dt,...
                            isStateFlow);
                    end
                    idx = args{1};
                    for i=2:numel(parameters)
                        v = args{i};
                        idx = BinaryExpr(BinaryExpr.PLUS,...
                            idx,...
                            BinaryExpr(BinaryExpr.MULTIPLY,...
                            BinaryExpr(BinaryExpr.MINUS, v, IntExpr(1)),...
                            IntExpr(prod(CompiledSize(1:i-1)))));
                    end
                    n = numel(namesAst);
                    conds = cell(n-1, 1);
                    thens = cell(n, 1);
                    for i=1:n-1
                        conds{i} = BinaryExpr(BinaryExpr.EQ, idx, IntExpr(i));
                        thens{i} = namesAst{i};
                    end
                    thens{n} = namesAst{n};
                    code = ParenthesesExpr(IteExpr.nestedIteExpr(conds, thens));
                end
            end
        end
        function code = SFGraphFunction(obj, tree, parent, ...
                blk, inputs, data_map, expected_dt, isStateFlow)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
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
                    args(i) = ...
                        nasa_toLustre.utils.Exp2Lus.tree2code(obj, parameters{i}, ...
                        parent, blk, node_inputs, data_map, params_dt{i},...
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
        
        %%
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
                dt = nasa_toLustre.utils.Exp2Lus.ID2DT(tree.name, inputs, data_map, isStateFlow);
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
                case {'plus_minus', 'mtimes', 'times', 'mrdivide', 'rdivide'}
                    left_dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree.leftExp, inputs, data_map, expected_dt, isStateFlow);
                    right_dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree.rightExp, inputs, data_map, expected_dt, isStateFlow);
                    dt = nasa_toLustre.utils.Exp2Lus.upperDT(left_dt, right_dt, expected_dt);
                    
                case 'unaryExpression'
                    if isequal(tree.operator, '~') || isequal(tree.operator, '!')
                        dt = 'bool';
                    else
                        dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree.rightExp, inputs, data_map, expected_dt, isStateFlow);
                    end
                case 'parenthesedExpression'
                    dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree.expression, inputs, data_map, expected_dt, isStateFlow);
                    
                case {'mpower', 'power'}
                    dt = 'real';
                    
                case 'assignment'
                    dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree.leftExp, inputs, data_map, expected_dt, isStateFlow);
                    
                case 'fun_indexing'
                    tree_ID = tree.ID;
                    switch tree_ID
                        case {'abs', 'sgn'}
                            dt = nasa_toLustre.utils.Exp2Lus.treeDT(tree.parameters(1), inputs, data_map, expected_dt, isStateFlow);
                        case 'rem'
                            param1 = nasa_toLustre.utils.Exp2Lus.treeDT(tree.parameters(1), inputs, data_map, expected_dt, isStateFlow);
                            param2 = nasa_toLustre.utils.Exp2Lus.treeDT(tree.parameters(2), inputs, data_map, expected_dt, isStateFlow);
                            dt = nasa_toLustre.utils.Exp2Lus.upperDT(param1, param2, expected_dt);
                        case {'sqrt', 'exp', 'log', 'log10',...
                                'sin','cos','tan',...
                                'asin','acos','atan','atan2', 'power', ...
                                'sinh','cosh', ...
                                'ceil', 'floor', 'hypot'}
                            dt = 'real';                
                        case {'all', 'any'}
                            dt = 'bool';
                        otherwise
                            dt = nasa_toLustre.utils.Exp2Lus.OtherFuncDT(tree, inputs, data_map, expected_dt, isStateFlow);
                    end
                otherwise
                    dt = expected_dt;
            end
            
        end
        
        function dt = OtherFuncDT(tree, inputs, data_map, expected_dt, isStateFlow)
            global SF_GRAPHICALFUNCTIONS_MAP SF_STATES_NODESAST_MAP;
            dt = expected_dt;
            
            if isStateFlow && data_map.isKey(tree.ID)
                dt = data_map(tree.ID).LusDatatype;
            elseif isStateFlow && SF_GRAPHICALFUNCTIONS_MAP.isKey(tree.ID)
                func = SF_GRAPHICALFUNCTIONS_MAP(tree.ID);
                sfNodename = SF_To_LustreNode.getUniqueName(func);
                nodeAst = SF_STATES_NODESAST_MAP(sfNodename);
                outputs = nodeAst.getOutputs();
                dt =  cell(numel(outputs), 1);
                for i=1:numel(outputs)
                    d = outputs{i};
                    dt{i} = d.getDT();
                end
            elseif ~isStateFlow && isequal(tree.ID, 'u')
                %"u" refers to an input in IF, Switch and Fcn
                %blocks
                if isequal(tree.parameters(1).type, 'constant')
                    %the case of u(1), u(2) ...
                    input_idx = str2double(tree.parameters(1).value);
                    dt = nasa_toLustre.utils.Exp2Lus.getVarDT(data_map, ...
                        inputs{1}{input_idx}.getId());
                    return;
                end
                
            elseif ~isStateFlow &&  ~isempty(regexp(tree.ID, 'u\d+', 'match'))
                % case of u1, u2 ...
                input_number = str2double(regexp(tree.ID, 'u(\d+)', 'tokens', 'once'));
                if isequal(tree.parameters(1).type, 'constant')
                    arrayIndex = str2double(tree.parameters(1).value);
                    dt = nasa_toLustre.utils.Exp2Lus.getVarDT(data_map, ...
                        inputs{input_number}{arrayIndex}.getId());
                    return;
                end
            end
        end
        
        
        function dt = ID2DT(id, inputs, data_map, isStateFlow)
            % the case of final term in a tree
            if strcmp(id, 'true') || strcmp(id, 'false')
                dt = 'bool';
                
            elseif ~isStateFlow && strcmp(id, 'u')
                %the case of u with no index
                dt = nasa_toLustre.utils.Exp2Lus.getVarDT(data_map, inputs{1}{1}.getId());
                
            elseif ~isStateFlow && ~isempty(regexp(id, 'u\d+', 'match'))
                input_idx = regexp(id, 'u(\d+)', 'tokens', 'once');
                dt = nasa_toLustre.utils.Exp2Lus.getVarDT(data_map, ...
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

