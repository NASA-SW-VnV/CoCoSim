function code = print_lustrec(obj, backend)

    code = '';
    try
        lhs_str = obj.lhs.print(backend);
        rhs_str = obj.rhs.print(backend);
        code = sprintf('%s = %s;', lhs_str, rhs_str);
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'LustreEq.print_lustrec', '');
    end
end
