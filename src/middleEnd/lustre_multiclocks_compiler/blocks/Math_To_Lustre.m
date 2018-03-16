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
        
        function  write_code(obj, parent, blk, varargin)
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            inputs = {};
            
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            for i=1:nbInputs
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType)
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end

            [outLusDT, ~, one] = SLX2LusUtils.get_lustre_dt(outputDataType);
            codes = {};
            operator = blk.Operator;
            if strcmp(operator, 'exp') || strcmp(operator, 'log')...
                    || strcmp(operator, 'log10') 
                
                obj.addExternal_libraries('lustrec_math');
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s(%s);\n\t', outputs{i}, operator,inputs{1}{i});
                end
                
            elseif strcmp(operator, '10^u')
                obj.addExternal_libraries('lustrec_math');
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = pow(10.0, %s);\n\t', outputs{i}, inputs{1}{i});
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
                    codes{i} = sprintf('%s = %s(%s, %s);\n\t', ...
                        outputs{i}, operator, inputs{1}{i}, inputs{2}{i});
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
                    codes{i} = sprintf('%s = sqrt(%s * %s + %s * %s);\n\t', outputs{i}, inputs{1}{i},inputs{1}{i}, inputs{2}{i},inputs{2}{i});
                end
            elseif strcmp(operator, 'rem')
                if strcmp(outLusDT, 'int')
                    obj.addExternal_libraries('rem_int_int');
                    fun = 'rem_int_int';
                else
                    obj.addExternal_libraries('simulink_math_fcn');
                    fun = 'rem_real';
                end
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s(%s, %s);\n\t',...
                        outputs{i}, fun, inputs{1}{i}, inputs{2}{i});
                end
            
            elseif strcmp(operator, 'mod')
                if strcmp(outLusDT, 'int')
                    obj.addExternal_libraries('simulink_math_fcn');
                    fun = 'mod_int';
                else
                    obj.addExternal_libraries('simulink_math_fcn');
                    fun = 'mod_real';

                end
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s(%s, %s);\n\t',...
                        outputs{i}, fun, inputs{1}{i}, inputs{2}{i});
                end
            elseif  strcmp(operator, 'transpose') || strcmp(operator, 'hermitian')          
                in_matrix_dimension = Product_To_Lustre.getInputMatrixDimensions(blk);
                if in_matrix_dimension{1}.numDs > 2
                    display_msg(sprintf('Matrix size > 2 is not supported for transpose/hermitian operator in block %s',...
                        blk.Origin_path), MsgType.ERROR, 'Math_To_Lustre', '');
                end
                
                outIndex = 0;
                for i=1:in_matrix_dimension{1}.dims(2)
                    for j=1:in_matrix_dimension{1}.dims(1)
                        outIndex = outIndex + 1;
                        inIndex = (j-1)*in_matrix_dimension{1}.dims(2)+i;
                        codes{outIndex} = sprintf('%s = %s;\n\t', outputs{outIndex}, inputs{1}{inIndex});  
                    end
                end 
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};

           
            options = obj.unsupported_options;
        end
    end
    
end

