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
        
        function  write_code(obj, parent, blk,xml_trace,  varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            inputs = {};
            obj.addExternal_libraries('lustrec_math');
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            for i=1:nbInputs
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, 'real')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'real');
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            
            operator = blk.Operator;
            codes = {};
            unsupportedOp = {'cos + jsin'};
            if ismember(operator, unsupportedOp)
                display_msg(sprintf('The "%s" operator is not supported in block %s',...
                    operator, blk.Origin_path), MsgType.ERROR, 'Trigonometry_To_Lustre', '');
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
            elseif strcmp(operator, 'atan2')
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s(%s, %s);\n\t', outputs{i}, operator,inputs{1}{i}, inputs{2}{i});
                end
            else
                for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s(%s);\n\t', outputs{i}, operator,inputs{1}{i});
                end
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            unsupportedOp = {'cos + jsin', 'tanh'};
            if ismember(blk.Operator, unsupportedOp)
                obj.addUnsupported_options(...
                    sprintf('The "%s" option is not supported in block %s', blk.Operator, blk.Origin_path));
            end
           
            options = obj.unsupported_options;
        end
    end
    
end

