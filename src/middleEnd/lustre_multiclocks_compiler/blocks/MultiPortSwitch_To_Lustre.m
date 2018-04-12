classdef MultiPortSwitch_To_Lustre < Block_To_Lustre
    %FromWorkspace_To_Lustre 
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
                [inLusDT] = SLX2LusUtils.get_lustre_dt(inport_dt);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType) && i~=1
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                elseif i==1 && ~strcmp(inLusDT, 'int')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'int');
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end

            [outLusDT, ~, one] = SLX2LusUtils.get_lustre_dt(outputDataType);
            codes = {};
            indexBlock = SLX2LusUtils.getpreBlock(parent, blk, 1);
            [indexValue, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, indexBlock, indexBlock.Value);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    indexBlock.Value, indexBlock.Origin_path), ...
                    MsgType.ERROR, 'MultiPortSwitch_To_Lustre', '');
                return;
            end
            switchIndex = int16(indexValue)+1;     
            
            [defaultIndex, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Inputs);
            
            defaultIndex = defaultIndex + 1;  % 1st port for control input
            if strcmp(blk.DataPortForDefault, 'Additional data port')
                defaultIndex = defaultIndex + 1;
            end            
               
            if strcmp(blk.DataPortOrder, 'Zero-based contiguous')
                switchIndex = switchIndex+1;
            elseif strcmp(blk.DataPortOrder, 'Specify indices')
                display_msg(sprintf('Specify indices is not supported  in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'MultiportSwitch_To_Lustre', '');
            end
            
            if ~isinteger(switchIndex) || switchIndex < 1 || switchIndex > defaultIndex  % else condition
                switchIndex = defaultIndex;
            end
            
            for i=1:numel(outputs)
                codes{i} = sprintf('%s = %s ;\n\t', outputs{i}, inputs{switchIndex}{i});
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            if strcmp(blk.DataPortOrder, 'Specify indices')
                obj.addUnsupported_options(...
                    sprintf('Specify indices is not supported  in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'MultiportSwitch_To_Lustre', '');
            end    
            if strcmp(blk.AllowDiffInputSizes, 'on')
                obj.addUnsupported_options(...
                    sprintf('Allow different data input sizes is not supported  in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'MultiportSwitch_To_Lustre', '');
            end             
            options = obj.unsupported_options;
        end
    end
    
end

