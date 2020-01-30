classdef MinMax_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %RelationalOperator_To_Lustre translates a RelationalOperator block
    %to Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            widths = blk.CompiledPortWidths.Inport;
            numInputs = numel(widths);
            max_width = max(widths);
            slxOutDT = blk.CompiledPortDataTypes.Outport{1};
            lusOutDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slxOutDT);
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            inputs = cell(1, numInputs);
            for i=1:numInputs
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                Lusinport_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{i});
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                %converts the input data type(s) to
                %its output data type
                if ~strcmp(Lusinport_dt, lusOutDT)
                    [external_lib, conv_format] = ...
                       nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(Lusinport_dt, slxOutDT, RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            
            op = strcat('_', blk.Function, '_', lusOutDT);
            obj.addExternal_libraries(strcat('LustMathLib_', op));
            if numInputs == 1
                code = nasa_toLustre.blocks.MinMax_To_Lustre.recursiveMinMax(op, inputs{1} );
                codes{1} = nasa_toLustre.lustreAst.LustreEq(outputs{1}, code);
            else
                codes = cell(1, max_width);
                for j=1:max_width
                    comparedElements = cell(1, numInputs);
                    for k=1:numInputs
                        comparedElements{k} = inputs{k}{j};
                    end
                    code = nasa_toLustre.blocks.MinMax_To_Lustre.recursiveMinMax(op, comparedElements);
                    codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, code);
                end
            end
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
            
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods (Static = true)
        res = recursiveMinMax(op, inputs)
        
    end
end

