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
        
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk);
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
                    inputs{1} = cellfun(@(x) sprintf(conv_format,x), inputs{1}, 'un', 0);
                end
            end
            
            
            obj.setCode(sprintf('%s = %s;\n\t', outputs{1}, ...
                Fcn_To_Lustre.expToLustre(obj, blk.Expr, parent, blk, inputs)));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            options = obj.unsupported_options;
        end
    end
    
    methods(Static)
        function lusCode = expToLustre(obj, exp, parent, blk, inputs)
            display_msg(exp, MsgType.DEBUG, 'Fcn_To_Lustre', '');
            lusCode = '';
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
                lusCode = sprintf('(if (%s) then 1.0 else 0.0)', lusCode);
            end
        end
        
        %%
        function code = tree2code(obj, tree, parent, blk, inputs, inputs_dt)
            %this function is extended to be used by If-Block, it's adapted
            %only to If, SwitchCase and Fcn blocks. 
            code = '';
            if ischar(tree)
                % the case of final term in a tree
                if strcmp(tree, 'u')
                    %the case of u with no index
                    code = inputs{1}{1};
                elseif ~isempty(regexp(tree, 'u\d+', 'match'))
                    input_idx = regexp(tree, 'u(\d+)', 'tokens', 'once');
                    code = char(inputs{str2double(input_idx)}{1});
                else
                    tokens = regexp(tree, '^[a-zA-z]\w*', 'match');
                    if isempty(tokens)
                        %numeric value
                        if strcmp(inputs_dt, 'real')
                            code = sprintf('%.18f', str2double(tree));
                        elseif strcmp(inputs_dt, 'bool')
                            if str2double(tree)
                                code = 'true';
                            else
                                code = 'false';
                            end
                        else
                            %tree might be 1 or 3e5
                            code = sprintf('%d', str2double(tree));
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
                            code = sprintf('%.18f', value);
                        elseif strcmp(inputs_dt, 'bool')
                            if value
                                code = 'true';
                            else
                                code = 'false';
                            end
                        else
                            code = num2str(value);
                        end
                    end
                end
                return;
            end
            switch tree{1}
                case 'Par'
                    code = sprintf('(%s)', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt));
                case 'Not'
                    code = sprintf('(not %s)', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt));
                case 'Plus'
                    code = sprintf('%s + %s', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                case 'Minus'
                    code = sprintf('%s - %s', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                case 'Mult'
                    code = sprintf('%s * %s', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                case 'Div'
                    code = sprintf('%s / %s', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                case 'Pow'
                    obj.addExternal_libraries('lustrec_math');
                    code = sprintf('pow(%s, %s)', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                case {'<', '>', '<=', '>='}
                    code = sprintf('%s %s %s', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        tree{1}, ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                    obj.isBooleanExpr = 1;
                case '=='
                    code = sprintf('%s = %s', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                    obj.isBooleanExpr = 1;
                case {'!=', '~='}
                    code = sprintf('%s <> %s', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                    obj.isBooleanExpr = 1;
                case {'&&', '&'}
                    code = sprintf('%s and %s', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                    obj.isBooleanExpr = 1;
                case {'||', '|'}
                    code = sprintf('%s or %s', ...
                        Fcn_To_Lustre.tree2code(obj, tree{2}, parent, blk, inputs, inputs_dt), ...
                        Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                    obj.isBooleanExpr = 1;
                    
                case 'Func'
                    switch tree{2}
                        % Handling function declared in ('Func','func_name','arg1', 'arg2, ..,'argn')
                        % with one argument. More than one argument are
                        % handled separately
                        
                        case 'abs'
                            code = sprintf('(if %s >= 0.0 then %s else -%s)', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt),...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt),...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                            
                        case {'sqrt', 'exp', 'log', 'log10',...
                                'sin','cos','tan',...
                                'asin','acos','atan', ...
                                'sinh','cosh'}
                            obj.addExternal_libraries('lustrec_math');
                            code = sprintf('%s(%s)', ...
                                tree{2}, Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                        case 'ceil'
                            obj.addExternal_libraries('_ceil');
                            code = sprintf('_ceil(%s)', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                            
                        case 'floor'
                            obj.addExternal_libraries('_floor');
                            code = sprintf('_floor(%s)', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                            
                        case 'sgn'
                            code = sprintf('(if %s > 0.0 then 1.0 else if %s < 0.0 then -1.0 else 0.0)', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt),...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt));
                        case 'rem'
                            obj.addExternal_libraries('simulink_math_fcn');
                            code = sprintf('rem_real(%s, %s)', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                                Fcn_To_Lustre.tree2code(obj, tree{4}, parent, blk, inputs, inputs_dt));
                            
                        case 'atan2'
                            obj.addExternal_libraries('lustrec_math');
                            code = sprintf('atan2(%s, %s)', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                                Fcn_To_Lustre.tree2code(obj, tree{4}, parent, blk, inputs, inputs_dt));
                        case 'hypot'
                            obj.addExternal_libraries('lustrec_math');
                            code = sprintf('sqrt(%s*%s, %s*%s)', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                                Fcn_To_Lustre.tree2code(obj, tree{4}, parent, blk, inputs, inputs_dt), ...
                                Fcn_To_Lustre.tree2code(obj, tree{4}, parent, blk, inputs, inputs_dt));
                        case 'power'
                            obj.addExternal_libraries('lustrec_math');
                            code = sprintf('pow(%s, %s)', ...
                                Fcn_To_Lustre.tree2code(obj, tree{3}, parent, blk, inputs, inputs_dt), ...
                                Fcn_To_Lustre.tree2code(obj, tree{4}, parent, blk, inputs, inputs_dt));
                        case 'u'
                            input_idx = str2double(tree{3});
                            code = sprintf('%s', ...
                                inputs{1}{input_idx});
                        otherwise
                            if ~isempty(regexp(tree{2}, 'u\d+', 'match'))
                                % case of u1, u2 ...
                                input_number = str2double(regexp(tree{2}, 'u(\d+)', 'tokens', 'once'));
                                arrayIndex = str2double(tree{3});
                                code = sprintf('%s', ...
                                    inputs{input_number}{arrayIndex});
                            else
                                try
                                    % eval in base expression such as
                                    % A(1,1) or single(1e-18) ...
                                    code = sprintf('%.18f', evalin('base', ...
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

