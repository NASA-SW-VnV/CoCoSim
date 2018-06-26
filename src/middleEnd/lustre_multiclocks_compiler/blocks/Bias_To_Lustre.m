classdef Bias_To_Lustre < Block_To_Lustre
    %Bias_To_Lustre 
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
            bias = blk.Bias;
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            [inputs,widths] = getBlockInputsNames_convInType2AccType(obj, parent, blk)
            bias = blk.Bias;

            [outLusDT, zero, one] = SLX2LusUtils.get_lustre_dt(outputDataType);
            codes = {};            
            for j=1:numel(inputs{1})
                codes{j} = sprintf('%s = %s + %s;', outputs{j}, inputs{1}{j},bias);
            end
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
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
    
    methods(Static)
        function [inputs,widths] = getBlockInputsNames_convInType2AccType(obj, parent, blk)
            inputs = {};
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            for i=1:numel(widths)
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
        end
        
    end
    
end

