classdef MinMax_To_Lustre < Block_To_Lustre
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
        
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            inputs = {};
            widths = blk.CompiledPortWidths.Inport;
            numInputs = numel(widths);
            max_width = max(widths);
            LusoutputDataType = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport{1});
            RndMeth = blk.RndMeth;
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
                        SLX2LusUtils.dataType_conversion(Lusinport_dt, LusoutputDataType, RndMeth);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            codes = {};
            op = strcat('_', blk.Function, '_', LusoutputDataType);
            obj.addExternal_libraries(op);
            if numInputs == 1
                code = MinMax_To_Lustre.recursiveMinMax(inputs{1} , op);
                codes{1} = sprintf('%s = %s;\n\t', outputs{1}, code);
            else
                for j=1:max_width
                    comparedElements = {};
                    for k=1:numInputs
                        comparedElements{k} = inputs{k}{j};
                    end
                    code = MinMax_To_Lustre.recursiveMinMax(comparedElements, op);
                    codes{j} = sprintf('%s = %s;\n\t', outputs{j}, code);
                end
            end
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj,parent, blk,  varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    methods (Static = true)
        function res = recursiveMinMax(inputs, op)
            n = numel(inputs);
            params = {};
            closedParent = '';
            for i=1:n-1
                params{i} = sprintf('%s(%s ', op , inputs{i});
                closedParent = [closedParent ')'];
            end
            params{n} = sprintf('%s ', inputs{n});
            
            res = sprintf('%s%s', ...
                MatlabUtils.strjoin(params, ', '), closedParent);
        end
        
    end
end

