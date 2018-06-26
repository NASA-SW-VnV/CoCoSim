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
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            inputs = {};
            
            if strcmp(blk.AllowDiffInputSizes, 'on')
                display_msg(sprintf('The Allow different data input sizes option is not support in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'Switch_To_Lustre', '');
            end
            
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            [threshold, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Threshold);
            secondInputIsBoolean = 0;
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType) && i~=2
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                elseif i==2
                    [lus_inportDataType, ~] = SLX2LusUtils.get_lustre_dt(inport_dt);
                    if strcmp(blk.Criteria, 'u2 ~= 0')
                        if strcmp(lus_inportDataType, 'real')
                            threshold_str = '0.0';
                        elseif strcmp(lus_inportDataType, 'int')
                            threshold_str = '0';
                        else
                            threshold_str = 'false';
                            secondInputIsBoolean = 1;
                        end
                    else
                        if strcmp(lus_inportDataType, 'real')
                            threshold_str = sprintf('%.15f', threshold);
                        elseif strcmp(lus_inportDataType, 'int')
                            threshold_str = sprintf('%d', int32(threshold));
                        else
                            secondInputIsBoolean = 1;
                        end
                    end
                end
            end
%             [~, zero] = SLX2LusUtils.get_lustre_dt(outputDataType);
            
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Threshold, blk.Origin_path), ...
                    MsgType.ERROR, 'Constant_To_Lustre', '');
                return;
            end
            codes = {};
            
            for i=1:numel(outputs)
                if secondInputIsBoolean
                    %TODO: the case of u2 >= Threshold in the case of
                    %boolean
                    cond = sprintf(' %s ', inputs{2}{i});
                else
                    if strcmp(blk.Criteria, 'u2 > Threshold')
                        cond = sprintf(' %s > %s ',inputs{2}{i}, threshold_str);
                    elseif strcmp(blk.Criteria, 'u2 >= Threshold')
                        cond = sprintf(' %s >= %s ',inputs{2}{i}, threshold_str);
                    elseif strcmp(blk.Criteria, 'u2 ~= 0')
                        cond = sprintf(' not(%s = %s) ',inputs{2}{i}, threshold_str);
                    end
                end
                codes{i} = sprintf('%s = if %s then %s else %s; \n\t', outputs{i}, cond, inputs{1}{i},inputs{3}{i});
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
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

