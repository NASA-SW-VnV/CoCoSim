classdef Math_To_Lustre < Block_To_Lustre
    %Math_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            operator = blk.Operator;
            needs_real_inputs = {'exp', 'log', 'log10', '10^u', 'sqrt', ...
                'pow', 'hypot'};
            if ismember(operator, needs_real_inputs)
                outputDataType = 'real';
            else
                outputDataType = blk.CompiledPortDataTypes.Outport{1};
            end
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            inputs = cell(1, nbInputs);
            for i=1:nbInputs
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType)
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, [], SaturateOnIntegerOverflow);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            
            [outLusDT, ~, one] = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport{1});
            if ismember(operator, needs_real_inputs)...
                    && ~isequal(outLusDT, 'real')
                [external_lib, conv_format] = SLX2LusUtils.dataType_conversion( 'real', outLusDT, [], SaturateOnIntegerOverflow);
                if ~isempty(external_lib)
                    obj.addExternal_libraries(external_lib);
                end
            else
                conv_format = {};
            end
            
            codes = cell(1, numel(outputs));
            
            if strcmp(operator, 'exp') || strcmp(operator, 'log')...
                    || strcmp(operator, 'log10') ...
                    || strcmp(operator, 'sqrt')
                
                obj.addExternal_libraries('LustMathLib_lustrec_math');
                for i=1:numel(outputs)
                    rhs = SLX2LusUtils.setArgInConvFormat(...
                        conv_format,...
                        NodeCallExpr(operator, inputs{1}{i}));
                    codes{i} = LustreEq(outputs{i}, rhs);
                end
                
            elseif strcmp(operator, '10^u')
                obj.addExternal_libraries('LustMathLib_lustrec_math');
                for i=1:numel(outputs)
                    rhs = SLX2LusUtils.setArgInConvFormat(...
                        conv_format,...
                        NodeCallExpr('pow', {RealExpr('10.0'), inputs{1}{i}}));
                    codes{i} = LustreEq(outputs{i}, rhs);
                end
                
                
            elseif strcmp(operator, 'square') || strcmp(operator, 'magnitude^2')
                % for real variables (not complexe) magnitude is the same
                % as square
                for i=1:numel(outputs)
                    codes{i} = LustreEq(...
                        outputs{i}, ...
                        BinaryExpr(BinaryExpr.MULTIPLY, inputs{1}{i},inputs{1}{i}));
                end
                
            elseif strcmp(operator, 'pow')
                
                obj.addExternal_libraries('LustMathLib_lustrec_math');
                for i=1:numel(outputs)
                    rhs = SLX2LusUtils.setArgInConvFormat(...
                        conv_format,...
                        NodeCallExpr(operator, ...
                        {inputs{1}{i}, inputs{2}{i}}));
                    codes{i} = LustreEq(outputs{i}, rhs);
                end
                
            elseif strcmp(operator, 'conj')
                % assume input is real not complex
                for i=1:numel(outputs)
                    codes{i} = LustreEq(outputs{i}, inputs{1}{i});
                end
                
            elseif strcmp(operator, 'reciprocal')
                for i=1:numel(outputs)
                    codes{i} = LustreEq(...
                        outputs{i}, ...
                        BinaryExpr(BinaryExpr.DIVIDE, one,inputs{1}{i}));
                end
                
            elseif strcmp(operator, 'hypot')
                obj.addExternal_libraries('LustMathLib_lustrec_math');
                for i=1:numel(outputs)
                    rhs = SLX2LusUtils.setArgInConvFormat(...
                        conv_format,...
                        NodeCallExpr('sqrt', ...
                        BinaryExpr(BinaryExpr.PLUS,...
                        BinaryExpr(BinaryExpr.MULTIPLY, ....
                        inputs{1}{i},...
                        inputs{1}{i}),...
                        BinaryExpr(BinaryExpr.MULTIPLY, ....
                        inputs{2}{i},...
                        inputs{2}{i})...
                        )));
                    codes{i} = LustreEq(outputs{i}, rhs);
                end
            elseif strcmp(operator, 'rem') || strcmp(operator, 'mod')
                if strcmp(outLusDT, 'int')
                    obj.addExternal_libraries(strcat('LustMathLib_', operator, '_int_int'));
                    fun = strcat(operator, '_int_int');
                else
                    fun = strcat(operator, '_real');
                    obj.addExternal_libraries('LustMathLib_simulink_math_fcn');
                end
                for i=1:numel(outputs)
                    codes{i} = LustreEq(outputs{i}, ...
                        NodeCallExpr(fun, ...
                        {inputs{1}{i}, inputs{2}{i}}));
                end
            elseif  strcmp(operator, 'transpose') || strcmp(operator, 'hermitian')
                in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
                if in_matrix_dimension{1}.numDs > 2
                    display_msg(sprintf('Matrix size > 2 is not supported for transpose/hermitian operator in block %s',...
                        HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'Math_To_Lustre', '');
                end
                if numel(in_matrix_dimension{1}.dims) == 1
                    in_matrix_dimension{1}.dims(2) = 1;
                end
                outIndex = 0;
                for j=1:in_matrix_dimension{1}.dims(1)
                    for i=1:in_matrix_dimension{1}.dims(2)
                        outIndex = outIndex + 1;
                        inIndex = sub2ind(in_matrix_dimension{1}.dims,j,i);
                        codes{outIndex} = LustreEq(outputs{outIndex},...
                            inputs{1}{inIndex}) ;
                    end
                end
            end
            
            obj.setCode(codes);
            obj.addVariable(outputs_dt);
        end
        %%
        function options = getUnsupportedOptions(obj, ~, blk,  varargin)
            if  strcmp(blk.Operator, 'transpose') || strcmp(blk.Operator, 'hermitian')
                in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
                if in_matrix_dimension{1}.numDs > 2
                    obj.addUnsupported_options(sprintf('Matrix size > 2 is not supported for transpose/hermitian operator in block %s',...
                        HtmlItem.addOpenCmd(blk.Origin_path)));
                end
            end
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(~, ~, ~, blk, varargin)
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

