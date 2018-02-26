classdef Sum_To_Lustre < Block_To_Lustre
    %Sum_To_Lustre The Sum block performs addition or subtraction on its 
    %inputs. This block can add or subtract scalar, vector, or matrix inputs. 
    %It can also collapse the elements of a signal.
    %The Sum block first converts the input data type(s) to 
    %its accumulator data type, then performs the specified operations. 
    %The block converts the result to its output data type using the 
    %specified rounding and overflow modes.
    
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
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            inputs = {};
            % get all inputs, Scalar inputs will be expanded to have 
            % the same dimensions as the other inputs
            OutputDataTypeStr = blk.OutDataTypeStr;
            AccumDataTypeStr = blk.AccumDataTypeStr;
            RndMeth = blk.RndMeth;
            if strcmp(AccumDataTypeStr, 'Inherit: Inherit via internal rule')
                AccumDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            elseif strcmp(AccumDataTypeStr, 'Inherit: Same as first input')
                AccumDataTypeStr = blk.CompiledPortDataTypes.Inport{1};
            end
            
            if strcmp(OutputDataTypeStr, 'Inherit: Inherit via internal rule')
                OutputDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            elseif strcmp(OutputDataTypeStr, 'Inherit: Same as first input')
                OutputDataTypeStr = blk.CompiledPortDataTypes.Inport{1};
            elseif strcmp(OutputDataTypeStr, 'Inherit: Same as accumulator')
                OutputDataTypeStr = AccumDataTypeStr;
            end
            
            
            
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to 
                %its accumulator data type
                if ~strcmp(inport_dt, AccumDataTypeStr)
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, AccumDataTypeStr, RndMeth);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            exp = blk.Inputs;
            % exp can be ++- or a number 3.
            % in the first case an operator is given for every input,
            % in the second case the operator is + for all inputs
            if ~isempty(str2num(exp))
                nb = str2num(exp);
                exp = arrayfun(@(x) '+', (1:nb));
            else
                % delete spacer character 
                exp = strrep(exp, '|', '');
            end
            
            [~, zero] = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport(1));
            [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(AccumDataTypeStr, OutputDataTypeStr, RndMeth);
            if ~isempty(external_lib)
                obj.addExternal_libraries(external_lib);
            end
            codes = {};
            if numel(exp) == 1 && numel(inputs) == 1
                % a Sum over the elements of same input.
                for i=1:numel(outputs)
                    code = zero;
                    for j=1:widths
                        code = sprintf('%s %s %s',code, exp(1), inputs{1}{j});
                    end
                    if ~isempty(conv_format)
                        code = sprintf(conv_format, code);
                    end
                    codes{i} = sprintf('%s = %s;\n\t', outputs{i}, code);
                end
            else
                for i=1:numel(outputs)
                    code = zero;
                    for j=1:numel(widths)
                        code = sprintf('%s %s %s',code, exp(j), inputs{j}{i});
                    end
                    if ~isempty(conv_format)
                        code = sprintf(conv_format, code);
                    end
                    codes{i} = sprintf('%s = %s;\n\t', outputs{i}, code);
                end
            end
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        
        %%
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    
end

