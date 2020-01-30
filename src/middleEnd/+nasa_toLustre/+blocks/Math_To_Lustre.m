classdef Math_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Math_To_Lustre

%    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            operator = blk.Operator;
            needs_real_inputs = {'exp', 'log', 'log10', '10^u', 'sqrt', ...
                'pow', 'hypot'};
            if ismember(operator, needs_real_inputs)
                convDataType = 'real';
            else
                convDataType = blk.CompiledPortDataTypes.Outport{1};
            end
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            inputs = cell(1, nbInputs);
            external_node_inputs_dt = {};
            inputs_trace_cell = {};
            for i=1:nbInputs
                [inputs{i}, in_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                external_node_inputs_dt = MatlabUtils.concat(external_node_inputs_dt, in_dt);
                in_trace = arrayfun(@(j) struct('VariableName', inputs{i}{j}.getId(),...
                    'OriginPath', fullfile(blk.Origin_path, strcat('u',num2str(i))), ...
                    'IsNotInSimulink', 1, 'PortNumber', i, ...
                    'Width', length(inputs{i}), 'Index', j, 'PortType', 'Inports'), ...
                    (1:length(inputs{i})), 'un', 0);
                inputs_trace_cell = MatlabUtils.concat(inputs_trace_cell, in_trace);
                
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, convDataType)
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, convDataType, [], SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            outSlxDT = blk.CompiledPortDataTypes.Outport{1};
            [outLusDT, ~, one] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outSlxDT);
            if ismember(operator, needs_real_inputs)...
                    && ~strcmp(outLusDT, 'real')
                [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion( 'real', outSlxDT, [], SaturateOnIntegerOverflow);
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                end
            else
                conv_format = {};
            end
            
            codes = cell(1, numel(outputs));
            % for traceability of abstracted block, we will create an external node for
            % the block calling the abstracted function
            external_node_outputs_dt = outputs_dt;
            need_to_abstract = false;
            external_node_body = cell(1, numel(outputs));
            node_name = nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            
            if strcmp(operator, 'exp') || strcmp(operator, 'log')...
                    || strcmp(operator, 'log10') ...
                    || strcmp(operator, 'sqrt')
                
                obj.addExternal_libraries('LustMathLib_lustrec_math');
                need_to_abstract = true;
                for i=1:numel(outputs)
                    rhs =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                        conv_format,...
                        nasa_toLustre.lustreAst.NodeCallExpr(operator, inputs{1}{i}));
                    external_node_body{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, rhs);
                end
                
                
            elseif strcmp(operator, '10^u')
                obj.addExternal_libraries('LustMathLib_lustrec_math');
                need_to_abstract = true;
                for i=1:numel(outputs)
                    rhs =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                        conv_format,...
                        nasa_toLustre.lustreAst.NodeCallExpr('pow', {nasa_toLustre.lustreAst.RealExpr('10.0'), inputs{1}{i}}));
                    external_node_body{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, rhs);
                end
                
                
            elseif strcmp(operator, 'square') || strcmp(operator, 'magnitude^2')
                % for real variables (not complexe) magnitude is the same
                % as square
                for i=1:numel(outputs)
                    b = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, inputs{1}{i}, inputs{1}{i});
                    b.setOperandsDT(outLusDT);
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, b);
                    
                end
                
            elseif strcmp(operator, 'pow')
                
                obj.addExternal_libraries('LustMathLib_lustrec_math');
                need_to_abstract = true;
                for i=1:numel(outputs)
                    rhs =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                        conv_format,...
                        nasa_toLustre.lustreAst.NodeCallExpr(operator, ...
                        {inputs{1}{i}, inputs{2}{i}}));
                    external_node_body{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, rhs);
                end
                
            elseif strcmp(operator, 'conj')
                % assume input is real not complex
                for i=1:numel(outputs)
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{1}{i});
                end
                
            elseif strcmp(operator, 'reciprocal')
                for i=1:numel(outputs)
                    rhs = nasa_toLustre.lustreAst.BinaryExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, ...
                        one, inputs{1}{i});
                    rhs.setOperandsDT(outLusDT);
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(...
                        outputs{i}, rhs);
                end
                
            elseif strcmp(operator, 'hypot')
                obj.addExternal_libraries('LustMathLib_lustrec_math');
                need_to_abstract = true;
                for i=1:numel(outputs)
                    b1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, ....
                        inputs{1}{i},...
                        inputs{1}{i});
                    b1.setOperandsDT('real');
                    b2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, ....
                        inputs{2}{i},...
                        inputs{2}{i});
                    b2.setOperandsDT('real');
                    rhs =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                        conv_format,...
                        nasa_toLustre.lustreAst.NodeCallExpr('sqrt', ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
                        b1, b2)));
                    external_node_body{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, rhs);
                end
            elseif strcmp(operator, 'rem') || strcmp(operator, 'mod')
                need_to_abstract = true;
                if strcmp(outLusDT, 'int')
                    obj.addExternal_libraries(strcat('LustMathLib_', operator, '_int_int'));
                    fun = strcat(operator, '_int_int');
                else
                    fun = strcat(operator, '_real');
                    obj.addExternal_libraries('LustMathLib_simulink_math_fcn');
                end
                for i=1:numel(outputs)
                    external_node_body{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                        nasa_toLustre.lustreAst.NodeCallExpr(fun, ...
                        {inputs{1}{i}, inputs{2}{i}}));
                end
            elseif  strcmp(operator, 'transpose') || strcmp(operator, 'hermitian')
                in_matrix_dimension = ...
                    nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(...
                    blk.CompiledPortDimensions.Inport);
                if in_matrix_dimension{1}.numDs > 2
                    display_msg(sprintf('Matrix size > 2 is not supported for transpose/hermitian operator in block %s',...
                        HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'Math_To_Lustre', '');
                end
                if numel(in_matrix_dimension{1}.dims) == 1
                    in_matrix_dimension{1}.dims(2) = 1;
                end
                
                mat_inputs = reshape(inputs{1}, in_matrix_dimension{1}.dims);
                mat_inputs_transpose = mat_inputs';
                Y_inlined = reshape(mat_inputs_transpose, [1, prod(in_matrix_dimension{1}.dims)]);
                
                for i=1:numel(outputs)
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, Y_inlined{i});
                end
                
            end
            
            
            obj.addVariable(outputs_dt);
            if need_to_abstract
                % Adding lustre comments tracking the original path
                comment = nasa_toLustre.lustreAst.LustreComment(...
                    sprintf('Original block name: %s', blk.Origin_path), true);
                contract = {};
                variables = {};
                obj.external_nodes{1} = nasa_toLustre.lustreAst.LustreNode(...
                    comment, ...
                    node_name,...
                    external_node_inputs_dt, ...
                    external_node_outputs_dt, ...
                    contract, ...
                    variables, ...
                    external_node_body, ...
                    false);
                orig_inputs = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.getId()), external_node_inputs_dt, 'UniformOutput', 0);
                code = nasa_toLustre.lustreAst.LustreEq(outputs,...
                    nasa_toLustre.lustreAst.NodeCallExpr(node_name, orig_inputs));
                obj.addCode({code});
                obj.blkIsAbstracted = true; 
                % traceability for counter examples
                outputs_trace_cell= arrayfun(@(i) struct('VariableName', outputs{i}.getId(),...
                    'OriginPath', fullfile(blk.Origin_path, 'y'), ...
                    'IsNotInSimulink', 1, 'PortNumber', 1, ...
                    'Width', length(outputs), 'Index', i, 'PortType', 'Inports'), ...
                    (1:length(outputs)), 'un', 0);
                xml_trace.create_abstractNode_Element(blk.Origin_path, ...
                node_name, inputs_trace_cell, outputs_trace_cell);
            else
                obj.addCode(codes);
            end
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    lusOutDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(convDataType);
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
        end
        %%
        function options = getUnsupportedOptions(obj, ~, blk,  varargin)
              %% TODO: Simulink does not support it too, remove this check             
%             if  strcmp(blk.Operator, 'transpose') || strcmp(blk.Operator, 'hermitian')
%                 in_matrix_dimension = nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
%                 if in_matrix_dimension{1}.numDs > 2
%                     obj.addUnsupported_options(sprintf('Matrix size > 2 is not supported for transpose/hermitian operator in block %s',...
%                         HtmlItem.addOpenCmd(blk.Origin_path)));
%                 end
%             end
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(obj, ~, blk, varargin)
            operator = blk.Operator;
            is_Abstracted = ~ (...
                strcmp(operator, 'transpose') ...
                || strcmp(operator, 'hermitian') ...
                || strcmp(operator, 'reciprocal') ...
                || strcmp(operator, 'conj') ...
                || strcmp(operator, 'square') ...
                || strcmp(operator, 'magnitude^2'));
        end
    end
    
end

