classdef Logic_To_Lustre < Block_To_Lustre
    %Logic_To_Lustre
    % supporting: AND, OR, NAND, NOR, XOR, NXOR, NOT
    
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
            
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType)
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            
            codes = {};
            for i=1:numel(outputs)
                scalars = {};
                for j=1:nbInputs
                    scalars{j} = inputs{j}{i};
                end
                if strcmp(blk.Operator, 'AND')
                    codes{i} = sprintf('%s = %s; \n\t', outputs{i}, MatlabUtils.strjoin(scalars, ' and '));
                elseif strcmp(blk.Operator, 'OR')
                    codes{i} = sprintf('%s = %s; \n\t', outputs{i}, MatlabUtils.strjoin(scalars, ' or '));
                elseif strcmp(blk.Operator, 'XOR')
                    codes{i} = sprintf('%s = %s; \n\t', outputs{i}, MatlabUtils.strjoin(scalars, ' xor '));
                elseif strcmp(blk.Operator, 'NOT')
                    codes{i} = sprintf('%s = not %s; \n\t', outputs{i}, inputs{1}{i});
                elseif strcmp(blk.Operator, 'NAND')
                    codes{i} = sprintf('%s = not(%s); \n\t', outputs{i}, MatlabUtils.strjoin(scalars, ' and '));
                elseif strcmp(blk.Operator, 'NOR')
                    codes{i} = sprintf('%s = not(%s); \n\t', outputs{i}, MatlabUtils.strjoin(scalars, ' or '));
                elseif strcmp(blk.Operator, 'NXOR')
                    codes{i} = sprintf('%s = not(%s); \n\t', outputs{i}, MatlabUtils.strjoin(scalars, ' xor '));
                end
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            % add your unsuported options list here
            
            options = obj.unsupported_options;
        end
    end
    
end

