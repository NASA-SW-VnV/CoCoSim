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
            [codes, outputs_dt, additionalVars] = Sum_To_Lustre.getSumProductCodes(obj, parent, blk, OutputDataTypeStr,isSumBlock,AccumDataTypeStr);
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
            obj.addVariable(additionalVars);
        end
        
        
        %%
        function options = getUnsupportedOptions(obj, parent,  blk, varargin)
            % add your unsuported options list here
            % if there is one input and the output dimension is > 7
            if numel(blk.CompiledPortWidths.Inport) == 1 ...
                    &&  numel(blk.CompiledPortDimensions.Outport) > 7
                obj.addUnsupported_options(...
                    sprintf('Dimension %s in block %s is not supported.',...
                    mat2str(blk.CompiledPortDimensions.Inport), blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
    end
    
    methods(Static)
        function [codes, outputs_dt, AdditinalVars] = getSumProductCodes(obj, parent, blk, OutputDataTypeStr,isSumBlock,AccumDataTypeStr)
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            inputs = {};
            RndMeth = blk.RndMeth;
            AdditinalVars = {};
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
            [LusOutputDataTypeStr, zero, one] = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport(1));
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
                [CollapseDim, ~, status] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, blk.CollapseDim);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        blk.CollapseDim, blk.Origin_path), ...
                        MsgType.ERROR, 'Sum_To_Lustre', '');
                    return;
                end
                collapseAllDims = 0;
                if strcmp(blk.CollapseMode, 'All dimensions')
                    collapseAllDims = 1;
                end
                
                if ~isSumBlock && strcmp(blk.Multiplication, 'Matrix(*)')    % product, 1 input, 1 exp, Matrix(x), matrix remains unchanged.
                    for i=1:numel(outputs)
                        codes{i} = sprintf('%s = %s;\n\t', outputs{i}, inputs{1}{i});
                    end
                    return;
                end
                
                if numel(outputs)>1        % needed for collapsing of matrix
                    in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk);
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
                
                for i=1:numel(outputs)
                    code = initCode;
                    if numel(outputs)==1
                        % if output is a scalar,
                        % operate over the elements of same input.
                        for j=1:widths
                            code = sprintf('%s %s %s',code, exp(1), inputs{1}{j});
                        end
                    else
                        % operate over the elements of same dimension in input.
                        % we support 7 dimesion for the moment.
                        if in_matrix_dimension{1}.numDs > 7
                            display_msg(sprintf('Dimension %s in block %s is not supported.',...
                                 mat2str(blk.CompiledPortDimensions.Inport), blk.Origin_path), ...
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
                        
                        code = sprintf('%s %s %s',code, exp(1), inputs{1}{inpIndex});

                        for j=2:numelCollapseDim 
                            code = sprintf('%s %s %s',code, exp(1), inputs{1}{inpIndex+(j-1)*delta});
                        end
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
                            MsgType.ERROR, 'Sum_To_Lustre', '');
                        return;
                    end
                    % check that the number of columns of 1st input matrix is equalled
                    % to the number of rows of the 2nd matrix
                    % matrix C(mxl) = A(mxn)*B(nxl)
                    
                    in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk);
                    % the index of the current matrix pair
                    pair_number = 0;
                    codes = {};
                    productOutputs = {};
                    tmp_prefix = SLX2LusUtils.node_name_format(blk);
                    for i=1:numel(in_matrix_dimension)-1
                        pair_number = pair_number + 1;
                        output_m = {};
                        m2_dimension = in_matrix_dimension{i+1};
                        if i==1
                            m1_inputs = inputs{1};
                            m1_dimension = in_matrix_dimension{i};
                        else
                            m1_inputs = productOutputs;
                            m1_dim.dims(1,1) = in_matrix_dimension{1}.dims(1,1);
                            m1_dim.dims(1,2) = in_matrix_dimension{i}.dims(1,2);
                            m1_dimension = m1_dim;
                        end
                        if i==numel(in_matrix_dimension)-1
                            output_m = outputs;
                        end
                                                   
                        [code, productOutputs, addVar] = Product_To_Lustre.matrix_multiply(m1_dimension, ...
                            m2_dimension, m1_inputs,...
                            inputs{i+1}, output_m, zero, pair_number, LusOutputDataTypeStr, tmp_prefix);   
                        codes = [codes, code];
                        %productOutputs = [productOutputs, tmp_outputs];
                        AdditinalVars = [AdditinalVars, addVar];
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

