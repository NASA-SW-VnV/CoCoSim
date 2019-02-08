
function [codes] = oneInputSumProduct(parent, blk, outputs, inputs, ...
        widths, exp, initCode,isSumBlock, conv_format)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            if ~isSumBlock && strcmp(blk.Multiplication, 'Matrix(*)')    % product, 1 input, 1 exp, Matrix(x), matrix remains unchanged.
                codes = cell(1, numel(outputs));
                for i=1:numel(outputs)
                    if ~isempty(conv_format)
                        code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,...
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
                    code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,code);
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
                        code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,code);
                    end
                    codes{i} = LustreEq(outputs{i}, code);
                end
            end
        end
