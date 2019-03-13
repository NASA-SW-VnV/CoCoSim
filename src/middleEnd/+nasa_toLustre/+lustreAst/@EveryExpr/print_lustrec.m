function code = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    args_str = nasa_toLustre.lustreAst.NodeCallExpr.getArgsStr(obj.nodeArgs, backend);
    code = sprintf('(%s(%s) every %s)', ...
        obj.nodeName, ...
        args_str,...
        obj.cond.print(backend));
end
