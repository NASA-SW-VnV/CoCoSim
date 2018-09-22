classdef Mux_To_Lustre < Block_To_Lustre
    % Mux_To_Lustre
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
            
            
            widths = blk.CompiledPortWidths.Inport;
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType)
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            
            codes = cell(1, numel(outputs));
            outputIndex = 0;
            for i=1:numel(widths)
                for j=1:numel(inputs{i})
                    outputIndex = outputIndex + 1;
                    codes{outputIndex} = LustreEq( outputs{outputIndex}, inputs{i}{j});
                end
            end
            
            
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.getUnsupportedOptions();
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

