function code = print_lustrec(obj, backend)

    code = sprintf('(%s)', ...
        nasa_toLustre.lustreAst.NodeCallExpr.getArgsStr(obj.args, backend));
end
