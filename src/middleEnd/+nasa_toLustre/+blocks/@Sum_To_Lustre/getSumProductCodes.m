%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [codes, outputs_dt, AdditionalVars, outputs] = getSumProductCodes(...
        obj, parent, blk, OutputDataTypeStr,isSumBlock, ...
        AccumDataTypeStr, xml_trace, lus_backend, main_sampleTime)
    
    AdditionalVars = {};
    codes = {};
    [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
    widths = blk.CompiledPortWidths.Inport;
    inputs = nasa_toLustre.blocks.Sum_To_Lustre.createBlkInputs(obj, parent, blk, widths, AccumDataTypeStr, isSumBlock);

    [LusOutputDataTypeStr, zero, one] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport(1));
    if (isSumBlock)
        operator_character = '+';
        initCode = zero;
    else
        operator_character = '*';
        initCode = one;
    end
    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(AccumDataTypeStr, OutputDataTypeStr, blk.RndMeth, blk.SaturateOnIntegerOverflow);
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
                codes{1} =nasa_toLustre.lustreAst.LustreEq(outputs,...
                    nasa_toLustre.lustreAst.NodeCallExpr(lib_name, inputs{1}));
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

        [codes] = nasa_toLustre.blocks.Sum_To_Lustre.oneInputSumProduct(parent, blk, outputs, ...
            inputs, widths, exp, initCode,isSumBlock, conv_format);
    else
        if ~isSumBlock && strcmp(blk.Multiplication, 'Matrix(*)')
            %This is a matrix multiplication, only applies to
            %Product block
            [codes, AdditionalVars] = nasa_toLustre.blocks.Product_To_Lustre.matrix_multiply(obj, exp, blk, inputs, outputs, zero, LusOutputDataTypeStr, conv_format );
        else
            % element wise operations / Sum
            % If it is integer division, we need to call the
            % appropriate division methode. We assume Lustre
            % division is the Euclidean division for integers.
            [LusInputDataTypeStr, ~, ~] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{1});
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
            [codes] = nasa_toLustre.blocks.Sum_To_Lustre.elementWiseSumProduct(exp, ...
                inputs, outputs, widths, initCode, conv_format, int_divFun);
        end
    end
end
