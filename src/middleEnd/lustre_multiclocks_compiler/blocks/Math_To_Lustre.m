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
        
        function  write_code(obj, parent, blk, xml_trace, ~, backend, varargin)
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            inputs = {};
            
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
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
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
                conv_format = '%s';
            end
                
            codes = {};
            
            if strcmp(operator, 'exp') || strcmp(operator, 'log')...
                    || strcmp(operator, 'log10') ...
                    || strcmp(operator, 'sqrt')
                
                obj.addExternal_libraries('lustrec_math');
                for i=1:numel(outputs)
                    rhs = sprintf(conv_format, ...
                        sprintf('%s(%s)', operator,inputs{1}{i}));
                    codes{i} = sprintf('%s = %s;\n\t', outputs{i}, rhs);
                end
                
            elseif strcmp(operator, '10^u')
                obj.addExternal_libraries('lustrec_math');
                for i=1:numel(outputs)
                    rhs = sprintf(conv_format, ...
                        sprintf('pow(10.0, %s)', inputs{1}{i}));
                    codes{i} = sprintf('%s = %s;\n\t', outputs{i}, rhs);
                end
                
                
            elseif strcmp(operator, 'square') || strcmp(operator, 'magnitude^2')
                % for real variables (not complexe) magnitude is the same
                % as square
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s * %s;\n\t', outputs{i}, inputs{1}{i},inputs{1}{i});
                end

            elseif strcmp(operator, 'pow')
                
                obj.addExternal_libraries('lustrec_math');
                for i=1:numel(outputs)
                    rhs = sprintf(conv_format, ...
                        sprintf('%s(%s, %s)', operator,inputs{1}{i}, inputs{2}{i}));
                    codes{i} = sprintf('%s = %s;\n\t', ...
                        outputs{i}, rhs);
                end
            elseif strcmp(operator, 'conj')
                % assume input is real not complex
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s;\n\t', outputs{i}, inputs{1}{i});
                end
                
            elseif strcmp(operator, 'reciprocal')
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s / %s;\n\t', outputs{i}, one, inputs{1}{i});
                end
                
            elseif strcmp(operator, 'hypot')
                obj.addExternal_libraries('lustrec_math');
                for i=1:numel(outputs)
                    rhs = sprintf(conv_format, ...
                        sprintf('sqrt(%s * %s + %s * %s)', ...
                        inputs{1}{i}, inputs{1}{i}, inputs{2}{i}, inputs{2}{i}));
                    codes{i} = sprintf('%s = %s;\n\t', outputs{i}, rhs);
                end
            elseif strcmp(operator, 'rem') || strcmp(operator, 'mod')
                if strcmp(outLusDT, 'int')
                    obj.addExternal_libraries(strcat(operator, '_int_int'));
                    fun = strcat(operator, '_int_int');
                else
                    fun = strcat(operator, '_real');
                    if BackendType.isKIND2(backend)
                        obj.addExternal_libraries(strcat('KIND2_', fun));
                    else
                        obj.addExternal_libraries('simulink_math_fcn');
                    end
                end
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s(%s, %s);\n\t',...
                        outputs{i}, fun, inputs{1}{i}, inputs{2}{i});
                end
            elseif  strcmp(operator, 'transpose') || strcmp(operator, 'hermitian')
                in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
                if in_matrix_dimension{1}.numDs > 2
                    display_msg(sprintf('Matrix size > 2 is not supported for transpose/hermitian operator in block %s',...
                        blk.Origin_path), MsgType.ERROR, 'Math_To_Lustre', '');
                end
                if numel(in_matrix_dimension{1}.dims) == 1
                    in_matrix_dimension{1}.dims(2) = 1;
                end
                outIndex = 0;
                for j=1:in_matrix_dimension{1}.dims(1)
                    for i=1:in_matrix_dimension{1}.dims(2)
                        outIndex = outIndex + 1;
                        inIndex = sub2ind(in_matrix_dimension{1}.dims,j,i);
                        codes{outIndex} = sprintf('%s = %s;\n\t', outputs{outIndex}, inputs{1}{inIndex});
                    end
                end
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            
            
            options = obj.unsupported_options;
        end
    end
    
end

