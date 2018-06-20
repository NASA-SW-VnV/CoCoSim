classdef Abs_To_Lustre < Block_To_Lustre
    %Abs_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                display_msg(sprintf('The minimum/maximum value is not supported in block %s',...
                    blk.Origin_path), MsgType.WARNING, 'Abs_To_Lustre', '');
            end
            if strcmp(blk.SaturateOnIntegerOverflow, 'on')
                display_msg(sprintf('The Saturate on integer overflow option is not support in block %s',...
                    blk.Origin_path), MsgType.WARNING, 'Abs_To_Lustre', '');
            end
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport(1);
            %converts the input data type(s) to
            %its accumulator data type
            if ~strcmp(inport_dt, outputDataType)
                RndMeth = blk.RndMeth;
                SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
                [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(external_lib)
                    obj.addExternal_libraries(external_lib);
                    inputs{1} = cellfun(@(x) sprintf(conv_format,x), inputs{1}, 'un', 0);
                end
            end
            
            [~, zero] = SLX2LusUtils.get_lustre_dt(outputDataType);
            
            codes = {};
            for j=1:numel(inputs{1})
                code = sprintf('if %s >= %s then %s else -%s', inputs{1}{j}, zero, inputs{1}{j}, inputs{1}{j});
                codes{j} = sprintf('%s = %s;', outputs{j}, code);
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, '\n\t'));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                obj.addUnsupported_options(...
                    sprintf('The minimum/maximum value is not supported in block %s', blk.Origin_path));
            end
            if strcmp(blk.SaturateOnIntegerOverflow, 'on')
                obj.addUnsupported_options(...
                    sprintf('The Saturate on integer overflow option is not support in block %s', blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
    end
    
end

