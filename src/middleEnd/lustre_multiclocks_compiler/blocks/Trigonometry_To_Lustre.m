classdef Trigonometry_To_Lustre < Block_To_Lustre
    %Abs_To_Lustre 
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

            operator = blk.Operator;       
            codes = {};
            
            if strcmp(operator, 'cos + jsin')
                display_msg(sprintf('The cos + jsin operator is not support in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'Trigonometry_To_Lustre', '');
            elseif strcmp(operator, 'tanh')
                display_msg(sprintf('The tanh operator is not support in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'Trigonometry_To_Lustre', '');                   
%             elseif strcmp(operator, 'atanh')
%                 display_msg(sprintf('The atanh operator is not support in block %s',...
%                     blk.Origin_path), MsgType.ERROR, 'Trigonometry_To_Lustre', '');                
            elseif strcmp(operator, 'sincos')
                index = 0;
                for i=1:widths
                    index = index + 1;
                    operator = 'sin';
                    codes{index} = sprintf('%s = %s(%s);\n\t', outputs{index}, operator,inputs{1}{i});
                end
                for i=1:widths
                    index = index + 1;
                    operator = 'cos';
                    codes{index} = sprintf('%s = %s(%s);\n\t', outputs{index}, operator,inputs{1}{i});
                end
            else
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s(%s);\n\t', outputs{i}, operator,inputs{1}{i});
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

