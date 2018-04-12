classdef Sqrt_To_Lustre < Block_To_Lustre
    % Sqrt_To_Lustre:
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
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                display_msg(sprintf('The minimum/maximum value is not support in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'Sqrt_To_Lustre', '');
            end
            if strcmp(blk.SaturateOnIntegerOverflow, 'on')
                display_msg(sprintf('The Saturate on integer overflow option is not support in block %s',...
                    blk.Origin_path), MsgType.WARNING, 'Sqrt_To_Lustre', '');
            end
            obj.addExternal_libraries('lustrec_math');
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            RndMeth = blk.RndMeth;
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, 'double')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'double', RndMeth);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            [outLusDT, zero, one] = SLX2LusUtils.get_lustre_dt(outputDataType);
            
            codes = {};
            for j=1:numel(inputs{1})
                if strcmp(blk.Operator, 'sqrt')
                    code = sprintf('sqrt(%s) ',  inputs{1}{j});

                elseif strcmp(blk.Operator, 'signedSqrt')
                    code = sprintf('if %s >= %s then sqrt(%s) else -sqrt(-%s)', inputs{1}{j}, zero, inputs{1}{j}, inputs{1}{j});
                elseif strcmp(blk.Operator, 'rSqrt')
                    code = sprintf('%s/sqrt(%s) ', one, inputs{1}{j});
                end
               
                 if ~strcmp(outLusDT, 'real')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion('real', outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        code = sprintf(conv_format,code);
                    end
                end
                codes{j} = sprintf('%s = %s;\n\t', outputs{j}, code);
            end
            if strcmp(blk.AlgorithmType, 'Newton-Raphson')
                msg = sprintf('Option Newton-Raphson is not supported in block %s', ...
                    blk.Origin_path);
                display_msg(msg, MsgType.WARNING, 'Sqrt_To_Lustre', '');
            end
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                obj.addUnsupported_options(...
                    sprintf('The minimum/maximum value is not support in block %s', blk.Origin_path));
            end
            if strcmp(blk.SaturateOnIntegerOverflow, 'on')
                obj.addUnsupported_options(...
                    sprintf('The Saturate on integer overflow option is not support in block %s', blk.Origin_path));
            end
            if strcmp(blk.AlgorithmType, 'Newton-Raphson')
                obj.addUnsupported_options(...
                sprintf('Option Newton-Raphson is not supported in block %s', ...
                    blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
       
    end
    
end

