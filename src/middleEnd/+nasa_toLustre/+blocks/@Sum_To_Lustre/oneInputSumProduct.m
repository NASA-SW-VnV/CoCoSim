%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [codes] = oneInputSumProduct(parent, blk, outputs, inputs, ...
        widths, exp, initCode,isSumBlock, conv_format)
            
            if ~isSumBlock && strcmp(blk.Multiplication, 'Matrix(*)')    % product, 1 input, 1 exp, Matrix(x), matrix remains unchanged.
                codes = cell(1, numel(outputs));
                for i=1:numel(outputs)
                    if ~isempty(conv_format)
                        code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,...
                            inputs{1}{i});
                    else
                        code = inputs{1}{i};
                    end
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, code);
                end
                return;
            end
            code = initCode;
            if numel(outputs)==1
                % if output is a scalar,
                % operate over the elements of same input.
                for j=1:widths
                    code = nasa_toLustre.lustreAst.BinaryExpr(exp(1), ...
                        code, inputs{1}{j}, false);
                end
                if ~isempty(conv_format)
                    code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,code);
                end
                codes{1} = nasa_toLustre.lustreAst.LustreEq(outputs{1}, code);
                
            elseif numel(outputs)>1        % needed for collapsing of matrix
                [CollapseDim, ~, status] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.CollapseDim);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        blk.CollapseDim, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                        MsgType.ERROR, 'Sum_To_Lustre', '');
                    return;
                end
                in_matrix_dimension = nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
                [numelCollapseDim, delta, collapseDims] = nasa_toLustre.blocks.Sum_To_Lustre.collapseMatrix(in_matrix_dimension, CollapseDim);
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
                    
                    code = nasa_toLustre.lustreAst.BinaryExpr(exp(1), ...
                        code, inputs{1}{inpIndex}, false);
                    
                    for j=2:numelCollapseDim
                        code = nasa_toLustre.lustreAst.BinaryExpr(exp(1), ...
                            code, inputs{1}{inpIndex+(j-1)*delta}, false);
                    end
                    
                    if ~isempty(conv_format)
                        code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,code);
                    end
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, code);
                end
            end
        end
