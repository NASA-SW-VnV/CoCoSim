
function [codes] = elementWiseSumProduct(exp, inputs, outputs, widths, initCode, conv_format, int_divFun)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
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
            code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format, code);
        end
        codes{i} = LustreEq(outputs{i}, code);
    end
end
