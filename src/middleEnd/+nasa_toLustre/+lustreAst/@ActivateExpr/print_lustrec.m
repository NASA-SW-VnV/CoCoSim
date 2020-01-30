function code = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    args_clocked = cellfun(@(x) nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.WHEN, x, obj.activate_cond), ...
        obj.nodeArgs, 'un', 0);
    args_str_cell = cellfun(@(x) x.print(backend), args_clocked, 'un', 0);
    args_str = MatlabUtils.strjoin(args_str_cell, ', ');
    nodeName = obj.nodeName;
    
    %PRELUDE does not support "_" in the begining of the word.
    if LusBackendType.isPRELUDE(backend) ...
            && MatlabUtils.startsWith(nodeName, '_')
        nodeName = sprintf('x%s', nodeName);
    end
    if obj.has_restart
        code = sprintf('(%s(%s) every %s)', ...
            nodeName, ...
            args_str,...
            obj.restart_cond.print(backend));
    else
        code = sprintf('%s(%s)', ...
            nodeName, ...
            args_str);
    end
end
