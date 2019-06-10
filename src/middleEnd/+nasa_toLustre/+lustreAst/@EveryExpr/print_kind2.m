function code = print_kind2(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    args_str = nasa_toLustre.lustreAst.NodeCallExpr.getArgsStr(obj.nodeArgs, backend);
    code = sprintf('(restart %s every %s)(%s)', ...
        obj.nodeName, ...
        obj.cond.print(backend),...
        args_str);
end
