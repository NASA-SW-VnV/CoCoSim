function code = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    code = '';
    try
        lhs_str = obj.lhs.print(backend);
        rhs_str = obj.rhs.print(backend);
        code = sprintf('%s = %s;', lhs_str, rhs_str);
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'LustreEq.print_lustrec', '');
    end
end
