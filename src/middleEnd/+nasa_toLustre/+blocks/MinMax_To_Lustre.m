classdef MinMax_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %RelationalOperator_To_Lustre translates a RelationalOperator block
    %to Lustre.
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
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            widths = blk.CompiledPortWidths.Inport;
            numInputs = numel(widths);
            max_width = max(widths);
            LusoutputDataType = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport{1});
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            inputs = cell(1, numInputs);
            for i=1:numInputs
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                Lusinport_dt = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{i});
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                %converts the input data type(s) to
                %its output data type
                if ~strcmp(Lusinport_dt, LusoutputDataType)
                    [external_lib, conv_format] = ...
                        SLX2LusUtils.dataType_conversion(Lusinport_dt, LusoutputDataType, RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            
            op = strcat('_', blk.Function, '_', LusoutputDataType);
            obj.addExternal_libraries(strcat('LustMathLib_', op));
            if numInputs == 1
                code = MinMax_To_Lustre.recursiveMinMax(op, inputs{1} );
                codes{1} = LustreEq(outputs{1}, code);
            else
                codes = cell(1, max_width);
                for j=1:max_width
                    comparedElements = cell(1, numInputs);
                    for k=1:numInputs
                        comparedElements{k} = inputs{k}{j};
                    end
                    code = MinMax_To_Lustre.recursiveMinMax(op, comparedElements);
                    codes{j} = LustreEq(outputs{j}, code);
                end
            end
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
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
        function res = recursiveMinMax(op, inputs)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            n = numel(inputs);
            if n == 1
                res = inputs{1};
            elseif n == 2
                res = NodeCallExpr(op, {inputs{1}, inputs{2}});
            else
                res = NodeCallExpr(op, ...
                    {inputs{1}, ...
                    MinMax_To_Lustre.recursiveMinMax(op,  inputs(2:end))});
            end
        end
        
    end
end

