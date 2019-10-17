classdef DotProduct_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % DotProduct_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        %% This block is handled by PP (DotProduct_pp.m)
        %TODO : remove this class, or pp function.
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            inputs = cell(1, numel(widths));
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its outputDataType
                if ~strcmp(inport_dt, outputDataType)
                    [external_lib, conv_format] =...
                        nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                        inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            
            [lusOutDT, ~] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            % if output in "int": add final result conversion to intXX
            if strcmp(lusOutDT, 'int')
                [external_lib, to_intxx_conv_format] = ...
                    nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                    'int', outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(to_intxx_conv_format)
                    obj.addExternal_libraries(external_lib);
                end
            else
                to_intxx_conv_format = {};
            end
            
            right = cell(1, numel(inputs{1}));
            for j=1:numel(inputs{1})
                right{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, ...
                    inputs{1}{j}, inputs{2}{j});
            end
            right_exp = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                nasa_toLustre.lustreAst.BinaryExpr.PLUS, right);
            if ~isempty(to_intxx_conv_format)
                right_exp = nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(to_intxx_conv_format,right_exp);
            end
            code = nasa_toLustre.lustreAst.LustreEq(outputs{1}, right_exp);
            obj.addCode( code );
            obj.addVariable(outputs_dt);
            
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    lusOutDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
        end
        %%
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            obj.unsupported_options = {...
                sprintf('Block %s is supported by Pre-processing check the pre-processing errors.',...
                HtmlItem.addOpenCmd(blk.Origin_path))};            
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

