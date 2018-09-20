classdef Fcn_To_Lustre < Block_To_Lustre
    %Fcn_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        isBooleanExpr = 0;
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport(1);
            %converts the input data type(s) to
            %its output data type
            if ~strcmp(inport_dt, outputDataType)
                RndMeth = blk.RndMeth;
                SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
                [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(external_lib)
                    obj.addExternal_libraries(external_lib);
                    inputs{1} = cellfun(@(x) ...
                        SLX2LusUtils.setArgInConvFormat(conv_format,x), inputs{1}, 'un', 0);
                end
            end
            
            
            obj.setCode(LustreEq(outputs{1}, ...
                Fcn_To_Lustre.expToLustre(obj, blk.Expr, parent, blk, inputs)));
            obj.addVariable(outputs_dt);
        end
        %%
        function options = getUnsupportedOptions(obj, varargin)
            obj.unsupported_options = {};
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(obj, varargin)
            is_Abstracted = ~isempty(obj.getExternalLibraries);
        end
    end
    
    methods(Static)
        function lusCode = expToLustre(obj, exp, parent, blk, inputs)
            display_msg(exp, MsgType.DEBUG, 'Fcn_To_Lustre', '');
            lusCode = VarIdExpr('');
            [tree, status, unsupportedExp] = Fcn_Exp_Parser(exp);
            if status
                display_msg(sprintf('ParseError  character unsupported  %s in block %s', ...
                    unsupportedExp, blk.Origin_path), ...
                    MsgType.ERROR, 'Fcn_To_Lustre', '');
                return;
            end
            obj.isBooleanExpr = 0;
            lusCode = Fcn_To_Lustre.tree2code(obj, tree, parent, blk, inputs, 'real');
            if obj.isBooleanExpr
                lusCode = IteExpr(lusCode, RealExpr('1.0'),  RealExpr('0.0'));
            end
            display_msg(lusCode.print('LUSTREC'), MsgType.DEBUG, 'Fcn_To_Lustre', '');
        end
        
        %%
        function code = tree2code(obj, tree, parent, blk, inputs, inputs_dt)
            %this function is extended to be used by If-Block, it's adapted
            %only to If, SwitchCase and Fcn blocks. 
            code = VarIdExpr('');
            if ischar(tree)
                % the case of final term in a tree
                if strcmp(tree, 'u')
                    %the case of u with no index
                    code = inputs{1}{1};
                elseif ~isempty(regexp(tree, 'u\d+', 'match'))
                    input_idx = regexp(tree, 'u(\d+)', 'tokens', 'once');
                    code = inputs{str2double(input_idx)}{1};
                else
                    tokens = regexp(tree, '^[a-zA-z]\w*', 'match');
                    if isempty(tokens)
                        %numeric value
                        if strcmp(inputs_dt, 'real')
                            code = RealExpr(str2double(tree));
                        elseif strcmp(inputs_dt, 'bool')
                            code = BooleanExpr(str2double(tree));
                        else
                            %tree might be 1 or 3e5
                            code = IntExpr(str2double(tree));
                        end
                    else
                        %check for variables in workspace
                        [value, ~, status] = ...
                            Constant_To_Lustre.getValueFromParameter(parent, blk, tokens{1});
                        if status
                            display_msg(sprintf('Not found Variable "%s" in block "%s"', tokens{1}, blk.Origin_path),...
                                MsgType.ERROR, 'Fcn_To_Lustre', '');
                            return;
                        end
                        if strcmp(inputs_dt, 'real')
                            code = RealExpr(value);
                        elseif strcmp(inputs_dt, 'bool')
                            code = BooleanExpr(value);
                        else
                            code = IntExpr(value);
                        end
                    end
                end
                return;
            end
            switch tree{1}
                case 'Par'
                    code = ParenthesesExpr(...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt));
                case 'Not'
                    code = UnaryExpr(UnaryExpr.NOT, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        false);
                case 'UnaryMinus'
                    code = UnaryExpr(UnaryExpr.NEG, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        false);
                case 'Plus'
                    code = BinaryExpr(BinaryExpr.PLUS, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                        false);
                case 'Minus'
                    code = BinaryExpr(BinaryExpr.MINUS, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                        false);
                case 'Mult'
                    code = BinaryExpr(BinaryExpr.MULTIPLY, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                        false);
                case 'Div'
                    code = BinaryExpr(BinaryExpr.DIVIDE, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                        false);
                case 'Pow'
                    obj.addExternal_libraries('LustMathLib_lustrec_math');
                    code = NodeCallExpr('pow', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                case {'<', '>', '<=', '>='}
                    code = BinaryExpr(tree{1}, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                        false);
                    obj.isBooleanExpr = 1;
                case '=='
                    code = BinaryExpr(BinaryExpr.EQ, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                        false);
                    obj.isBooleanExpr = 1;
                case {'!=', '~='}
                    code = BinaryExpr(BinaryExpr.NEQ, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                        false);
                    obj.isBooleanExpr = 1;
                case {'&&', '&'}
                    code = BinaryExpr(BinaryExpr.AND, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                        false);
                    obj.isBooleanExpr = 1;
                case {'||', '|'}
                    code = BinaryExpr(BinaryExpr.OR, ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                        false);
                    obj.isBooleanExpr = 1;
                    
                case 'Func'
                    switch tree{2}
                        % Handling function declared in ('Func','func_name','arg1', 'arg2, ..,'argn')
                        % with one argument. More than one argument are
                        % handled separately
                        
                        case 'abs'
                            code = IteExpr(...
                                BinaryExpr(BinaryExpr.GTE, ...
                                    Fcn_To_Lustre.tree2code(obj, tree{3}, ...
                                        parent, blk, inputs, inputs_dt), ...
                                    RealExpr('0.0')), ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, ...
                                    parent, blk, inputs, inputs_dt), ...
                                UnaryExpr(UnaryExpr.NEG, ...
                                  Fcn_To_Lustre.tree2code(obj, tree{3}, ...
                                    parent, blk, inputs, inputs_dt)));
                            
                        case {'sqrt', 'exp', 'log', 'log10',...
                                'sin','cos','tan',...
                                'asin','acos','atan', ...
                                'sinh','cosh'}
                            obj.addExternal_libraries('LustMathLib_lustrec_math');
                            code = NodeCallExpr(tree{2},...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                        case 'ceil'
                            obj.addExternal_libraries('LustDTLib__ceil');
                            code = NodeCallExpr('_ceil', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                            
                        case 'floor'
                            obj.addExternal_libraries('LustDTLib__floor');
                            code = NodeCallExpr('_floor', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                            
                        case 'sgn'
                            exp = Fcn_To_Lustre.tree2code(obj, tree{3}, ...
                               parent, blk, inputs, inputs_dt);
                            code = IteExpr.nestedIteExpr(...
                                {BinaryExpr(BinaryExpr.GT, ...
                                            exp, ...
                                            RealExpr('0.0')), ...
                                 BinaryExpr(BinaryExpr.LT, ...
                                             exp, ...
                                             RealExpr('0.0'))}, ...
                                {RealExpr('1.0'), ...
                                RealExpr('-1.0'),...
                                RealExpr('0.0')});
                        case 'rem'
                            obj.addExternal_libraries('LustMathLib_simulink_math_fcn');
                            code = NodeCallExpr('rem_real', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                                Fcn_To_Lustre.tree2code(obj, tree{4}, parent, blk, inputs, inputs_dt));
                            
                        case 'atan2'
                            obj.addExternal_libraries('LustMathLib_lustrec_math');
                            code = NodeCallExpr('atan2', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                                Fcn_To_Lustre.tree2code(obj, tree{4}, parent, blk, inputs, inputs_dt));
                        case 'hypot'
                            obj.addExternal_libraries('LustMathLib_lustrec_math');
                            arg1 = Fcn_To_Lustre.tree2code(obj, tree{3}, ...
                                parent, blk, inputs, inputs_dt);
                            arg1 = BinaryExpr(BinaryExpr.MULTIPLY, arg1, arg1);
                            arg2 = Fcn_To_Lustre.tree2code(obj, tree{4},...
                                parent, blk, inputs, inputs_dt);
                            arg2 = BinaryExpr(BinaryExpr.MULTIPLY, arg2, arg2);
                            code = NodeCallExpr('sqrt', arg1, arg2);
                        case 'power'
                            obj.addExternal_libraries('LustMathLib_lustrec_math');
                            code = NodeCallExpr('pow', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                                Fcn_To_Lustre.tree2code(obj, tree{4}, parent, blk, inputs, inputs_dt));
                        case 'u'
                            input_idx = str2double(tree{3});
                            code = inputs{1}{input_idx};
                        otherwise
                            if ~isempty(regexp(tree{2}, 'u\d+', 'match'))
                                % case of u1, u2 ...
                                input_number = str2double(regexp(tree{2}, 'u(\d+)', 'tokens', 'once'));
                                arrayIndex = str2double(tree{3});
                                code = inputs{input_number}{arrayIndex};
                            else
                                try
                                    % eval in base expression such as
                                    % A(1,1) or single(1e-18) ...
                                    code = RealExpr(evalin('base', ...
                                        sprintf('%s(%s)', tree{2}, ...
                                        MatlabUtils.strjoin(tree(3:end), ', '))));
                                catch
                                    display_msg(sprintf('Function not handled : %s in Block %s',...
                                        tree{2}, blk.Origin_path),...
                                        MsgType.ERROR, 'Fcn_To_Lustre', '');
                                end
                            end
                    end
                otherwise
                    display_msg(sprintf('Expression %s not handled in Block %s',...
                        tree{2}, blk.Origin_path),...
                        MsgType.ERROR, 'Fcn_To_Lustre', '');
            end
            
        end
    end
    
end

