function code = print_lustrec(obj, backend)

    args_str = nasa_toLustre.lustreAst.NodeCallExpr.getArgsStr(obj.enum_args, backend);
    code = sprintf('type %s = enum {%s};\n', obj.enum_name, args_str);
end
