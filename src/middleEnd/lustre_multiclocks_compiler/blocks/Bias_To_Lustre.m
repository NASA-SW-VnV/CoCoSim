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
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            [inputs] = Bias_To_Lustre.getBlockInputsNames_convInType2AccType(obj, parent, blk);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};

            [outLusDT] = SLX2LusUtils.get_lustre_dt(outputDataType);
            if isequal(outLusDT, 'int')
                bias = IntExpr(blk.Bias);
            else
                bias = RealExpr(blk.Bias);
            end
            n = numel(inputs{1});
            codes = cell(1, n);            
            for j=1:n
                %codes{j} = sprintf('%s = %s + %s;', outputs{j}, inputs{1}{j},bias);
                codes{j} = LustreEq(...
                    outputs{j}, ...
                    BinaryExpr(BinaryExpr.PLUS, ...
                                inputs{1}{j}, ...
                                bias));
            end
            obj.setCode(codes);
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
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
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
                        inputs{i} = cellfun(@(x)...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end            
        end
        
    end
    
end

