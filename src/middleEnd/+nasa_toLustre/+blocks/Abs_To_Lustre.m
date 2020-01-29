classdef Abs_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Abs_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            [outputs, outputs_dt] = nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport{1};
            
            %converts the input data type(s) to
            %its accumulator data type
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            if ~strcmp(inport_dt, outputDataType)
                [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                end
            else
                conv_format = {};
            end
            
            [lusOutDT, ~] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            
            % if output in "int": add final result conversion to intXX
            if strcmp(lusOutDT, 'int') && isempty(conv_format)
                [external_lib, conv_format] = ...
                    nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                    'int', outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                end
            end
            [~, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
            codes = cell(1, numel(inputs{1}));
            for j=1:numel(inputs{1})
                conds = cell(1, 1);
                thens = cell(1, 2);
                conds{1} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.GTE, ...
                    inputs{1}{j}, zero);
                thens{1} = inputs{1}{j};
                thens{2} = nasa_toLustre.lustreAst.UnaryExpr(...
                    nasa_toLustre.lustreAst.UnaryExpr.NEG, ...
                    inputs{1}{j});
                code = ...
                   nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                    conv_format,...
                    nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
                codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, code);
            end
            
            obj.addCode(codes);
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

