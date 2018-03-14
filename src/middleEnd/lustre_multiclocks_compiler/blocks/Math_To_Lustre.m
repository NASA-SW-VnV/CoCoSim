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
            operator = blk.Operator;
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            inputs = {};
            obj.addExternal_libraries('lustrec_math');
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

            [outLusDT, zero, one] = SLX2LusUtils.get_lustre_dt(outputDataType);
            codes = {};
            
            if strcmp(operator, 'hermitian')
                display_msg(sprintf('The hermitian operator is not support in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'Trigonometry_To_Lustre', '');
            elseif strcmp(operator, 'transpose')
                display_msg(sprintf('The transpose operator is not support in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'Trigonometry_To_Lustre', '');    
            elseif strcmp(operator, 'rem')
                display_msg(sprintf('The rem operator is not support in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'Trigonometry_To_Lustre', '');     
            elseif strcmp(operator, '10^u')
                display_msg(sprintf('The 10^u operator is not support in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'Trigonometry_To_Lustre', '');                   
            else
                for i=1:numel(outputs)
                    if strcmp(operator, 'square')
                        codes{i} = sprintf('%s = %s*%s;\n\t', outputs{i}, inputs{1}{i},inputs{1}{i});
                    elseif strcmp(operator, 'conj')
                        codes{i} = sprintf('%s = %s;\n\t', outputs{i}, inputs{1}{i});  % assume input is real not complex
                    elseif strcmp(operator, 'reciprocal')
                        codes{i} = sprintf('%s = %s / %s;\n\t', outputs{i}, one, inputs{1}{i}); 
                    elseif strcmp(operator, 'hypot')
                        codes{i} = sprintf('%s = sqrt(%s*%s+%s*%s);\n\t', outputs{i}, inputs{1}{i},inputs{1}{i}, inputs{2}{i},inputs{2}{i});
                    elseif strcmp(operator, 'rem')
                        codes{i} = sprintf('%s = rem(%s,%s);\n\t', outputs{i}, inputs{1}{i},inputs{2}{i});    
                    elseif strcmp(operator, 'pow')
                        codes{i} = sprintf('%s = rem(%s,%s);\n\t', outputs{i}, inputs{1}{i},inputs{2}{i});    
                    else
                        if strcmp(operator, '10^u')
                            operator = 'ArrayPowerBase10';
                        elseif strcmp(operator, 'mod')
                            operator = 'modulo';
                        end
                        codes{i} = sprintf('%s = %s(%s);\n\t', outputs{i}, operator,inputs{1}{i});
                    end
                end
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};
            if strcmp(blk.Operator, 'cos + jsin')
                obj.addUnsupported_options(...
                    sprintf('The cos + jsin option is not support in block %s', blk.Origin_path));
            end 
            if strcmp(blk.Operator, 'atanh')
                obj.addUnsupported_options(...
                    sprintf('The atanh option is not support in block %s', blk.Origin_path));
            end   
            if strcmp(blk.Operator, 'tanh')
                obj.addUnsupported_options(...
                    sprintf('The tanh option is not support in block %s', blk.Origin_path));
            end             
            options = obj.unsupported_options;
        end
    end
    
end

