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
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, varargin)
            
            OutputDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            AccumDataTypeStr = blk.AccumDataTypeStr;
            if strcmp(AccumDataTypeStr, 'Inherit: Inherit via internal rule')
                AccumDataTypeStr = blk.CompiledPortDataTypes.Outport{1};
            elseif strcmp(AccumDataTypeStr, 'Inherit: Same as first input')
                AccumDataTypeStr = blk.CompiledPortDataTypes.Inport{1};
            end
            
           
            isSumBlock = true;
            [codes, outputs_dt, additionalVars] = ...
                Sum_To_Lustre.getSumProductCodes(obj, parent, blk, ...
                OutputDataTypeStr,isSumBlock,AccumDataTypeStr, xml_trace, lus_backend);
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
            obj.addVariable(additionalVars);
        end
        
        
        %%
        function options = getUnsupportedOptions(obj, ~,  blk, varargin)
            % if there is one input and the output dimension is > 7
            if numel(blk.CompiledPortWidths.Inport) == 1 ...
                    &&  numel(blk.CompiledPortDimensions.Outport) > 7
                obj.addUnsupported_options(...
                    sprintf('Dimension %s in block %s is not supported.',...
                    mat2str(blk.CompiledPortDimensions.Inport), HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    methods(Static)
        function [codes, outputs_dt, AdditionalVars] = getSumProductCodes(...
                obj, parent, blk, OutputDataTypeStr,isSumBlock, ...
                AccumDataTypeStr, xml_trace, lus_backend)
            AdditionalVars = {};
            codes = {};
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            widths = blk.CompiledPortWidths.Inport;
            inputs = Sum_To_Lustre.createBlkInputs(obj, parent, blk, widths, AccumDataTypeStr, isSumBlock);
            
            [LusOutputDataTypeStr, zero, one] = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport(1));
            if (isSumBlock)
                operator_character = '+';
                initCode = zero;
            else
                operator_character = '*';
                initCode = one;
            end
            [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(AccumDataTypeStr, OutputDataTypeStr, blk.RndMeth, blk.SaturateOnIntegerOverflow);
            if ~isempty(conv_format)
                obj.addExternal_libraries(external_lib);
            end
            exp = blk.Inputs;
            if strcmp(exp, '/') && strcmp(blk.Multiplication, 'Matrix(*)')
                if numel(outputs) > 1
                    % inverse of Matrix
                    n = sqrt(numel(outputs));
                    if n > 7
                        display_msg(...
                            sprintf('Option Matrix(*) with is not supported for more than 7 dimensions in block %s', ...
                            HtmlItem.addOpenCmd(blk.Origin_path)), ...
                            MsgType.ERROR, 'Product_To_Lustre', '');
                        return;
                    elseif n > 4 && ~LusBackendType.isKIND2(lus_backend)
                         display_msg(...
                            sprintf('Option Matrix(*) with division (inverse) is not supported for Matrix dimension > 4 in block %s', ...
                            HtmlItem.addOpenCmd(blk.Origin_path)), ...
                            MsgType.ERROR, 'Product_To_Lustre', '');
                        return;
                    else
                        lib_name = sprintf('_inv_M_%dx%d', n, n);
                        obj.addExternal_libraries(strcat('LustMathLib_', lib_name));
                        codes{1} =LustreEq(outputs,...
                            NodeCallExpr(lib_name, inputs{1}));
                        return;
                    end
                    
                end
            end
            % for sum:
            %    exp can be ++- or a number 3 .
            %    in the first case an operator is given for every input,
            %    in the second case the operator is + for all inputs
            % DO NOt USE str2double instead of str2num
            if ~isempty(str2num(exp))
                nb = str2num(exp);
                exp = arrayfun(@(x) operator_character, (1:nb));
            else
                % delete spacer character
                exp = strrep(exp, '|', '');
            end
                    
            if numel(exp) == 1 && numel(inputs) == 1
                % one input and 1 expression
                
                [codes] = Sum_To_Lustre.oneInputSumProduct(parent, blk, outputs, ...
                    inputs, widths, exp, initCode,isSumBlock, conv_format);
            else
                if ~isSumBlock && strcmp(blk.Multiplication, 'Matrix(*)')
                    %This is a matrix multiplication, only applies to
                    %Product block
                    [codes, AdditionalVars] = Product_To_Lustre.matrix_multiply(obj, exp, blk, inputs, outputs, zero, LusOutputDataTypeStr, conv_format );
                else
                    % element wise operations / Sum
                    % If it is integer division, we need to call the
                    % appropriate division methode. We assume Lustre
                    % division is the Euclidean division for integers.
                    [LusInputDataTypeStr, ~, ~] = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{1});
                    if strcmp(LusOutputDataTypeStr, 'int') ...
                            && strcmp(LusInputDataTypeStr, 'int') ...
                            && MatlabUtils.contains(exp, '/')
                        if strcmp(blk.RndMeth, 'Round')...
                                || strcmp(blk.RndMeth, 'Convergent')...
                                || strcmp(blk.RndMeth, 'Simplest')
                            display_msg(sprintf('Rounding method "%s" for integer division is not supported in block "%s".',...
                                blk.RndMeth, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                                MsgType.WARNING, 'Sum_To_Lustre', '');
                            int_divFun = '';
                        else
                            int_divFun = sprintf('int_div_%s', blk.RndMeth);
                            obj.addExternal_libraries(strcat('LustMathLib_',...
                                int_divFun));
                        end
                    else
                        int_divFun = '';
                    end
                    [codes] = Sum_To_Lustre.elementWiseSumProduct(exp, ...
                        inputs, outputs, widths, initCode, conv_format, int_divFun);
                end
            end
        end
        %%
        function inputs = createBlkInputs(obj, parent, blk, widths, AccumDataTypeStr, isSumBlock)
            max_width = max(widths);
            
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            inputs = cell(1, numel(widths));
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
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, AccumDataTypeStr, RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
                
            end
        end
        %%
        function [codes] = elementWiseSumProduct(exp, inputs, outputs, widths, initCode, conv_format, int_divFun)
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                code = initCode;
                for j=1:numel(widths)
                    if ~isempty(int_divFun) && strcmp(exp(j), '/')
                        code = NodeCallExpr(int_divFun,...
                            {code, inputs{j}{i}});
                    else
                        code = BinaryExpr(exp(j), ...
                            code, inputs{j}{i}, false);
                    end
                end
                if ~isempty(conv_format)
                    code = SLX2LusUtils.setArgInConvFormat(conv_format, code);
                end
                codes{i} = LustreEq(outputs{i}, code);
            end
        end
        %%
        
        function [codes] = oneInputSumProduct(parent, blk, outputs, inputs, ...
                widths, exp, initCode,isSumBlock, conv_format)
            if ~isSumBlock && strcmp(blk.Multiplication, 'Matrix(*)')    % product, 1 input, 1 exp, Matrix(x), matrix remains unchanged.
                codes = cell(1, numel(outputs));
                for i=1:numel(outputs)
                    if ~isempty(conv_format)
                        code = SLX2LusUtils.setArgInConvFormat(conv_format,...
                            inputs{1}{i});
                    else
                        code = inputs{1}{i};
                    end
                    codes{i} = LustreEq(outputs{i}, code);
                end
                return;
            end
            code = initCode;
            if numel(outputs)==1
                % if output is a scalar,
                % operate over the elements of same input.
                for j=1:widths
                    code = BinaryExpr(exp(1), ...
                        code, inputs{1}{j}, false);
                end
                if ~isempty(conv_format)
                    code = SLX2LusUtils.setArgInConvFormat(conv_format,code);
                end
                codes{1} = LustreEq(outputs{1}, code);
                
            elseif numel(outputs)>1        % needed for collapsing of matrix
                [CollapseDim, ~, status] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, blk.CollapseDim);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        blk.CollapseDim, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                        MsgType.ERROR, 'Sum_To_Lustre', '');
                    return;
                end
                in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
                [numelCollapseDim, delta, collapseDims] = Sum_To_Lustre.collapseMatrix(in_matrix_dimension, CollapseDim);
                % the variable matSize is used in eval function, do not
                % remove it.
                matSize = in_matrix_dimension{1}.dims;
                codes = cell(1, numel(outputs));
                for i=1:numel(outputs)
                    code = initCode;
                    
                    % operate over the elements of same dimension in input.
                    % we support 7 dimesion for the moment.
                    if in_matrix_dimension{1}.numDs > 7
                        display_msg(sprintf('Dimension %s in block %s is not supported.',...
                            mat2str(blk.CompiledPortDimensions.Inport), HtmlItem.addOpenCmd(blk.Origin_path)), ...
                            MsgType.ERROR, 'Sum_To_Lustre', '');
                        return;
                    end
                    [d1, d2, d3, d4, d5, d6, d7 ] = ind2sub(collapseDims,i);   % 7 dims max
                    subscripts(1) = d1;
                    subscripts(2) = d2;
                    subscripts(3) = d3;
                    subscripts(4) = d4;
                    subscripts(5) = d5;
                    subscripts(6) = d6;
                    subscripts(7) = d7;
                    sub2ind_string = 'inpIndex = sub2ind(matSize';
                    for j=1:in_matrix_dimension{1}.numDs
                        sub2ind_string = sprintf('%s, %d',sub2ind_string,subscripts(j));
                    end
                    sub2ind_string = sprintf('%s);',sub2ind_string);
                    eval(sub2ind_string);
                    
                    code = BinaryExpr(exp(1), ...
                        code, inputs{1}{inpIndex}, false);
                    
                    for j=2:numelCollapseDim
                        code = BinaryExpr(exp(1), ...
                            code, inputs{1}{inpIndex+(j-1)*delta}, false);
                    end
                    
                    if ~isempty(conv_format)
                        code = SLX2LusUtils.setArgInConvFormat(conv_format,code);
                    end
                    codes{i} = LustreEq(outputs{i}, code);
                end
            end
        end
        %%
        function [numelCollapseDim, delta, collapseDims] = collapseMatrix(in_matrix_dimension, CollapseDim)
            numelCollapseDim = in_matrix_dimension{1}.dims(CollapseDim);
            matSize = in_matrix_dimension{1}.dims;
            
            subscripts = ones(1,in_matrix_dimension{1}.numDs);
            subscripts(CollapseDim) = 2;
            sub2ind_string = 'ind1 = sub2ind(matSize';
            for j=1:in_matrix_dimension{1}.numDs
                sub2ind_string = sprintf('%s, 1',sub2ind_string);
            end
            sub2ind_string = sprintf('%s);',sub2ind_string);
            eval(sub2ind_string);
            sub2ind_string = 'ind2 = sub2ind(matSize';
            for j=1:in_matrix_dimension{1}.numDs
                sub2ind_string = sprintf('%s, %d',sub2ind_string,subscripts(j));
            end
            sub2ind_string = sprintf('%s);',sub2ind_string);
            eval(sub2ind_string);
            delta = ind2-ind1;
            collapseDims = matSize;
            collapseDims(CollapseDim) = 1;
        end
    end
    
end

