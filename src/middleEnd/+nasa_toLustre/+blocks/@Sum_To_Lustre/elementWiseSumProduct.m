%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [codes] = elementWiseSumProduct(exp, inputs, outputs, widths, initCode, conv_format, int_divFun, operandsDT)
    
    codes = cell(1, numel(outputs));
    for i=1:numel(outputs)
        code = initCode;
        for j=1:numel(widths)
            if ~isempty(int_divFun) && strcmp(exp(j), '/')
                code = nasa_toLustre.lustreAst.NodeCallExpr(int_divFun,...
                    {code, inputs{j}{i}});
            else
                code = nasa_toLustre.lustreAst.BinaryExpr(exp(j), ...
                    code, inputs{j}{i}, false);
                code.setOperandsDT(operandsDT);
            end
            
        end
        if ~isempty(conv_format)
            code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format, code);
        end
        codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, code);
    end
end
