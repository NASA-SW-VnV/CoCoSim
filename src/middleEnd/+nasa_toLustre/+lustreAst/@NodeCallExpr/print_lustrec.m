function code = print_lustrec(obj, backend)

    nodeName = obj.nodeName;
    %PRELUDE does not support "_" in the begining of the word.
    if LusBackendType.isPRELUDE(backend) ...
            && MatlabUtils.startsWith(nodeName, '_')
        nodeName = sprintf('x%s', nodeName);
    end
    code = sprintf('%s(%s)', ...
        nodeName, ...
       nasa_toLustre.lustreAst.NodeCallExpr.getArgsStr(obj.args, backend));
end
