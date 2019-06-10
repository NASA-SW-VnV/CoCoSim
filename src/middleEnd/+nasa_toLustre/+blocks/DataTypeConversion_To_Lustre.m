classdef DataTypeConversion_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % DataTypeConversion_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, varargin)
            global  CoCoSimPreferences;
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);

            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;

            inputs =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            inport_dt = blk.CompiledPortDataTypes.Inport{1};
            %converts the input data type(s) to
            %its outputDataType
            if ~strcmp(inport_dt, outputDataType)
                [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                    inputs= cellfun(@(x) ...
                        nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                        inputs, 'un', 0);
                end
            end
            
            % Just pass inputs to outputs.
            codes = arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{i}), ...
                (1:numel(outputs)), 'UniformOutput', false);
            
            obj.addCode(codes);
            obj.addVariable(outputs_dt);
            
            
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    lusOutDT = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
            
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    

    
end

