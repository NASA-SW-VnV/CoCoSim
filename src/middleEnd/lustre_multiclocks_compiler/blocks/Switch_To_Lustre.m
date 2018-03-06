classdef Switch_To_Lustre < Block_To_Lustre
    % Switch_To_Lustre
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
            
            if strcmp(blk.AllowDiffInputSizes, 'on')
                display_msg(sprintf('The Allow different data input sizes option is not support in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'Switch_To_Lustre', '');
            end            
            
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
                if ~strcmp(inport_dt, outputDataType)
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            [~, zero] = SLX2LusUtils.get_lustre_dt(outputDataType);
            threshold = blk.Threshold;

            codes = {};
            if strcmp(blk.Criteria, 'u2 > Threshold')
                    codes{1} = sprintf('if %s > %s then %s else %s \n\t',  inputs{1,2}{1}, threshold,inputs{1,1}{1},inputs{1,3}{1});
            elseif strcmp(blk.Criteria, 'u2 >= Threshold')
                    codes{1} = sprintf('if %s >= %s then %s else %s \n\t',  inputs{1,2}{1}, threshold,inputs{1,1}{1},inputs{1,3}{1});
            elseif strcmp(blk.Criteria, 'u2 ~= 0')
                    codes{1} = sprintf('if not(%s > %s) then %s else %s \n\t',  inputs{1,2}{1}, threshold,inputs{1,1}{1},inputs{1,3}{1});
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, '\n\t'));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};
            if ~isempty(blk.OutMax) || ~isempty(blk.OutMin)
                obj.unsupported_options{numel(obj.unsupported_options) + 1} = sprintf('The minimum/maximum value is not support in block %s', blk.Origin_path);
            end
            if strcmp(blk.SaturateOnIntegerOverflow, 'on')
                obj.unsupported_options{numel(obj.unsupported_options) + 1} = sprintf('The Saturate on integer overflow option is not support in block %s', blk.Origin_path);
            end 
%             if strcmp(blk.AllowDiffInputSizes, 'on')
%                 obj.unsupported_options{numel(obj.unsupported_options) + 1} = sprintf('The Allow different data input sizes option is not support in block %s', blk.Origin_path);
%             end             
            options = obj.unsupported_options;
        end
    end
    
end

