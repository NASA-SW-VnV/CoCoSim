classdef Demux_To_Lustre < Block_To_Lustre
    % Demux_To_Lustre
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
            
            if strcmp(blk.BusSelectionMode, 'on')
                display_msg(sprintf('BusSelectionMode on is not supported in block %s',...
                    blk.Origin_path), ...
                    MsgType.ERROR, 'Demux_To_Lustre', '');
            end
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            
            widths = blk.CompiledPortWidths.Inport;
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            % one input
            i=1;
            inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
            inport_dt = blk.CompiledPortDataTypes.Inport(i);
            %converts the input data type(s) to
            %its accumulator data type
            if ~strcmp(inport_dt, outputDataType)
                [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                if ~isempty(external_lib)
                    obj.addExternal_libraries(external_lib);
                    inputs{i} = cellfun(@(x) ...
                        SLX2LusUtils.setArgInConvFormat(conv_format,x), ...
                        inputs{i}, 'un', 0);
                end
            end
            
            
            codes = cell(1, widths);
            for i=1:widths
                codes{i} = LustreEq(outputs{i}, inputs{1}{i});
                %sprintf('%s = %s;\n\t', outputs{i}, inputs{1}{i});
            end
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            if strcmp(blk.BusSelectionMode, 'on')
                obj.addUnsupported_options(...
                    sprintf('BusSelectionMode on is not supported in block %s',...
                    blk.Origin_path), ...
                    MsgType.ERROR, 'Demux_To_Lustre', '');
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

