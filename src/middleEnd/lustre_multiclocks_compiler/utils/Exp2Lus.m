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
        function [lusCode, status] = expToLustre(BlkObj, exp, parent, blk, inputs, data_map, expected_dt)
            lusCode = VarIdExpr('');
            try
                em2json =  cocosim.matlab2IR.EM2JSON;
                IR_string = em2json.StringToIR(exp);
                IR = json_decode(IR_string);
                tree = IR.statements(1);
            catch me
                display_msg(sprintf('ParseError for expression "%s" in block %s', ...
                    exp, blk.Origin_path), ...
                    MsgType.ERROR, 'Exp2Lus.expToLustre', '');
                display_msg(me.getReport(), MsgType.DEBUG, 'Exp2Lus.expToLustre', '');
                return;
            end
            try
                lusCode = Exp2Lus.tree2code(BlkObj, tree, parent, blk, inputs, data_map, expected_dt);
            catch me
                status = 1;
                if strcmp(me.identifier, 'COCOSIM:TREE2CODE')
                    display_msg(me.message, MsgType.ERROR, 'Exp2Lus.expToLustre', '');
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
                code = constant2code(tree.value, expected_dt);
                return;
            end
            switch tree_type
                case {'plus_minus', 'mtimes', 'mrdivide', ...
                        'relopGL', 'relopEQ_NE', '!=', '~=', ...
                        '&&', '&', '||', '|'}
                    if isequal(tree_type, 'plus_minus')
                        op = tree.operator;
                    elseif isequal(tree_type, 'mtimes')
                        op = BinaryExpr.MULTIPLY;
                    elseif isequal(tree_type, 'mrdivide')
                        op = BinaryExpr.DIVIDE;
                    elseif isequal(tree_type, 'relopEQ_NE')
                        op = tree.operator;
                        obj.isBooleanExpr = 1;
                    elseif isequal(tree_type, 'relopGL')
                        op = tree.operator;
                        obj.isBooleanExpr = 1;
                    elseif ismember(tree_type, {'!=', '~='})
                        op = BinaryExpr.NEQ;
                        obj.isBooleanExpr = 1;
                    elseif ismember(tree_type, {'&&', '&'})
                        op = BinaryExpr.AND;
                        obj.isBooleanExpr = 1;
                    elseif ismember(tree_type, {'||', '|'})
                        op = BinaryExpr.OR;
                        obj.isBooleanExpr = 1;
                    else
                        op = tree_type;
                    end
                    code = BinaryExpr(op, ...
                        Exp2Lus.tree2code(obj, tree{2}, parent, blk, inputs, data_map, expected_dt, isStateFlow), ...
                        Exp2Lus.tree2code(obj, tree{3}, parent, blk, inputs, data_map, expected_dt, isStateFlow), ...
                        false);
                case 'Par'
                    code = ParenthesesExpr(...
                        Exp2Lus.tree2code(obj, tree{2}, parent, blk, inputs, data_map, expected_dt, isStateFlow));
                case 'Not'
                    code = UnaryExpr(UnaryExpr.NOT, ...
                        Exp2Lus.tree2code(obj, tree{2}, parent, blk, inputs, data_map, expected_dt, isStateFlow), ...
                        false);
                case 'UnaryMinus'
                    code = UnaryExpr(UnaryExpr.NEG, ...
                        Exp2Lus.tree2code(obj, tree{2}, parent, blk, inputs, data_map, expected_dt, isStateFlow), ...
                        false);

                case 'Pow'
                    obj.addExternal_libraries('LustMathLib_lustrec_math');
                    code = NodeCallExpr('pow', ...
                        Exp2Lus.tree2code(obj, tree{2}, parent, blk, inputs, data_map, expected_dt, isStateFlow), ...
                        Exp2Lus.tree2code(obj, tree{3}, parent, blk, inputs, data_map, expected_dt, isStateFlow));
                case '='
                    code = LustreEq(...
                        Exp2Lus.tree2code(obj, tree{2}, parent, blk, inputs, data_map, expected_dt, isStateFlow), ...
                        Exp2Lus.tree2code(obj, tree{3}, parent, blk, inputs, data_map, expected_dt, isStateFlow) ...
                        );
                 
                case 'Array'
                    code = Exp2Lus.parseOtherFunc(obj, tree, ...
                        parent, blk, inputs, data_map, expected_dt, isStateFlow, ...
                        '[', ']');
                case 'Func'
                    switch tree{2}
                        %functions with one argument
                        case {'sqrt', 'exp', 'log', 'log10',...
                                'sin','cos','tan',...
                                'asin','acos','atan', ...
                                'sinh','cosh', ...
                                'abs', 'sgn', ...
                                'ceil', 'floor'}
                            if isequal(tree{2}, 'abs') ...
                                    || isequal(tree{2}, 'sgn') 
                                fun_name = strcat(tree{2}, '_', expected_dt);
                                lib_name = strcat('LustMathLib_', fun_name);
                                obj.addExternal_libraries(lib_name);
                                
                            elseif ismember(tree{2}, ...
                                    {'sqrt', 'exp', 'log', 'log10',...
                                    'sin','cos','tan',...
                                    'asin','acos','atan', ...
                                    'sinh','cosh'})
                                fun_name = tree{2};
                                obj.addExternal_libraries('LustMathLib_lustrec_math');
                                
                            elseif isequal(tree{2}, 'ceil') ...
                                    || isequal(tree{2}, 'floor')
                                fun_name = strcat('_', tree{2});
                                lib_name = strcat('LustDTLib_', fun_name);
                                obj.addExternal_libraries(lib_name);
                                
                            else
                                fun_name = tree{2};
                                
                            end
                            code = NodeCallExpr(fun_name,...
                                Exp2Lus.tree2code(obj, tree{3}, parent, blk, inputs, data_map, expected_dt, isStateFlow));
                            
                        %function with two arguments
                        case {'rem', 'atan2', 'power'}
                            if isequal(tree{2}, 'atan2') ...
                                    || isequal(tree{2}, 'power') 
                                obj.addExternal_libraries('LustMathLib_lustrec_math');
                                if isequal(tree{2}, 'power')
                                    fun_name = 'pow';
                                else
                                    fun_name = tree{2};
                                end
                            elseif isequal(tree{2}, 'rem')
                                if isequal(expected_dt, 'int')
                                    fun_name = 'rem_int_int';
                                    lib_name = strcat('LustMathLib_', fun_name);
                                    obj.addExternal_libraries(lib_name);
                                else
                                    obj.addExternal_libraries('LustMathLib_simulink_math_fcn');
                                    fun_name = 'rem_real';
                                end
                            else
                                fun_name = tree{2};
                            end
                            
                            code = NodeCallExpr(fun_name, ...
                                Exp2Lus.tree2code(obj, tree{3}, parent, blk, inputs, data_map, expected_dt, isStateFlow), ...
                                Exp2Lus.tree2code(obj, tree{4}, parent, blk, inputs, data_map, expected_dt, isStateFlow));
                            
                        case 'hypot'
                            obj.addExternal_libraries('LustMathLib_lustrec_math');
                            arg1 = Exp2Lus.tree2code(obj, tree{3}, ...
                                parent, blk, inputs, data_map, expected_dt, isStateFlow);
                            arg1 = BinaryExpr(BinaryExpr.MULTIPLY, arg1, arg1);
                            arg2 = Exp2Lus.tree2code(obj, tree{4},...
                                parent, blk, inputs, data_map, expected_dt, isStateFlow);
                            arg2 = BinaryExpr(BinaryExpr.MULTIPLY, arg2, arg2);
                            code = NodeCallExpr('sqrt', arg1, arg2);
                        otherwise
                            code = Exp2Lus.parseOtherFunc(obj, tree, ...
                                parent, blk, inputs, data_map, expected_dt, isStateFlow, ...
                                '(', ')');
                    end
                otherwise
                    if isStateFlow
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Expression "%s" not handled in Stateflow',...
                            tree{2});
                    else
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Expression "%s" not handled in Block %s',...
                            tree{2}, blk.Origin_path);
                    end
                    throw(ME);
            end
            
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
                
                dt = data_map(id).LusDatatype;
                if isequal(dt, expected_dt)
                    code = VarIdExpr(id);
                else
                    [external_lib, conv_format] =...
                        SLX2LusUtils.dataType_conversion(dt, expected_dt);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        code = ...
                            SLX2LusUtils.setArgInConvFormat(...
                            conv_format, VarIdExpr(id));
                    else
                        code = VarIdExpr(id);
                    end
                end
            else
                %code = VarIdExpr(var_name);
                ME = MException('COCOSIM:TREE2CODE', ...
                    'Not found Variable "%s" in block "%s"', ...
                    id, blk.Origin_path);
                throw(ME);
            end
        end
        function code = parseOtherFunc(obj, tree, parent, blk, inputs, expected_dt, isStateFlow, lpar, rpar)
            code = '';
            if isequal(tree{2}, 'u')
                if isStateFlow
                    %TODO: u(..) in Stateflow?
                else
                    %u refers to an input in IF, Switch and Fcn
                    %blocks
                    input_idx = str2double(tree{3});
                    code = inputs{1}{input_idx};
                end
            elseif ~isempty(regexp(tree{2}, 'u\d+', 'match'))
                % case of u1, u2 ...
                if isStateFlow
                    %TODO: u1(..) in Stateflow?
                else
                    input_number = str2double(regexp(tree{2}, 'u(\d+)', 'tokens', 'once'));
                    arrayIndex = str2double(tree{3});
                    code = inputs{input_number}{arrayIndex};
                end
            else
                try
                    % eval in base expression such as
                    % A(1,1) or single(1e-18) ...
                    exp = sprintf('%s%s%s%s', tree{2}, lpar, ...
                        MatlabUtils.strjoin(tree(3:end), ', '), rpar);
                    [value, ~, status] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, exp);
                    if status
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Not found Variable "%s" in block "%s"', ...
                            tokens{1}, blk.Origin_path);
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
                        args = {};
                        for i=3:numel(tree)
                            args{end + 1} = ...
                                Exp2Lus.tree2code(obj, tree{i}, ...
                                parent, blk, inputs, expected_dt, isStateFlow);
                        end
                        code = NodeCallExpr(tree{2}, args);
                    else
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Function "%s" is not handled in Block %s',...
                            tree{2}, blk.Origin_path);
                        throw(ME);
                    end
                end
            end
        end
        
        
    end
end

