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
            
            OutputDataTypeStr = blk.OutDataTypeStr;
            AccumDataTypeStr = blk.AccumDataTypeStr;
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
            
            isSumBlock = true;
            [codes, outputs_dt] = Sum_To_Lustre.getSumProductCodes(obj, parent, blk, OutputDataTypeStr,isSumBlock,AccumDataTypeStr);
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        
        %%
        function options = getUnsupportedOptions(obj,blk, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    
    methods(Static)
        function [codes, outputs_dt] = getSumProductCodes(obj, parent, blk, OutputDataTypeStr,isSumBlock,AccumDataTypeStr)
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            inputs = {};
            RndMeth = blk.RndMeth;
            
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    if ~(~isSumBlock && strcmp(blk.Multiplication, 'Matrix(*)'))
                        inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                    end
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
            [~, zero, one] = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport(1));
            if (isSumBlock)
                operator_character = '+';
                initCode = zero;
            else
                operator_character = '*';
                initCode = one;
            end
            [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(AccumDataTypeStr, OutputDataTypeStr, RndMeth);
            if ~isempty(external_lib)
                obj.addExternal_libraries(external_lib);
            end
            exp = blk.Inputs;
            % for sum:
            %    exp can be ++- or a number 3 .
            %    in the first case an operator is given for every input,
            %    in the second case the operator is + for all inputs
            if ~isempty(str2num(exp))
                nb = str2num(exp);
                exp = arrayfun(@(x) operator_character, (1:nb));
            else
                % delete spacer character
                exp = strrep(exp, '|', '');
            end
            
            codes = {};
            
            if numel(exp) == 1 && numel(inputs) == 1
                % one input and 1 expression
                % operate over the elements of same input.  Add/multiply
                % all elements and output a scalar
                for i=1:numel(outputs)
                    code = initCode;
                    for j=1:widths
                        code = sprintf('%s %s %s',code, exp(1), inputs{1}{j});
                    end
                    if ~isempty(conv_format)
                        code = sprintf(conv_format, code);
                    end
                    codes{i} = sprintf('%s = %s;\n\t', outputs{i}, code);
                end
            else
                if ~isSumBlock && strcmp(blk.Multiplication, 'Matrix(*)')
                    %This is a matrix multiplication, only applies to
                    %Product block
                    if  contains(exp, '/')
                        display_msg(...
                            sprintf('Option Matrix(*) with divid is not supported in block %s', ...
                            blk.Origin_path), ...
                            MsgType.ERROR, 'getSumProductCodes', '');
                        return;
                    end
                    % check that the number of columns of 1st input matrix is equalled
                    % to the number of rows of the 2nd matrix
                    % matrix C(mxl) = A(mxn)*B(nxl)
                    initCode = sprintf('%s ',zero);
                    m=blk.CompiledPortDimensions.Inport(2);
                    n=blk.CompiledPortDimensions.Inport(3);
                    l=blk.CompiledPortDimensions.Inport(5);
                    codeIndex = 0;
                    for i=1:m      %i is row of result matrix
                        for j=1:l      %j is column of result matrix
                            codeIndex = codeIndex + 1;
                            code = initCode;
                            for k=1:n
                                aIndex = (i-1)*n+k
                                bIndex = (k-1)*l+j
                                code = sprintf('%s + (%s * %s)',code, inputs{1,1}{1,aIndex},inputs{1,2}{1,bIndex});
                                if ~isempty(conv_format)
                                    code = sprintf(conv_format, code);
                                end    
                                diag = sprintf('i %d, j %d, k %d, aIndex %d, bIndex %d',i,j,k,aIndex,bIndex)
                            end
                            
                            codes{codeIndex} = sprintf('%s = %s;\n\t', outputs{codeIndex}, code) 
                        end
                        
                    end
                    
                    
                else
                    % element wise operations
                    for i=1:numel(outputs)
                        code = initCode;
                        for j=1:numel(widths)
                            code = sprintf('%s %s %s',code, exp(j), inputs{j}{i});
                        end
                        if ~isempty(conv_format)
                            code = sprintf(conv_format, code);
                        end
                        codes{i} = sprintf('%s = %s;\n\t', outputs{i}, code);
                    end
                end
            end
        end
    end
    
end

