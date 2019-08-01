function [code, exp_dt, dim] = numFun_To_Lustre(tree, args)
    % used by zerosFun_To_Lustre and onesFun_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    c = symvar(tree.text);
    exp_dt = '';
    code = {};
    dim = [];
    if isempty(c)
        try
            x = eval(tree.text);
        catch
            ME = MException('COCOSIM:TREE2CODE', ...
                'Expression "%s" is not supported.',...
                tree.text);
            throw(ME);
        end
        expected_dt = args.expected_lusDT;
        dim = size(x);
        if strcmp(expected_dt, 'int') ...
                || (isempty(expected_dt) && isinteger(x))
            for i=1:numel(x)
                code{i} =  nasa_toLustre.lustreAst.IntExpr(x(i));
            end
            exp_dt = 'int';
        else
            for i=1:numel(x)
                code{i} =  nasa_toLustre.lustreAst.RealExpr(x(i));
            end
            exp_dt = 'real';
        end
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            'Using variable "%s" in expression "%s" is not supported.',...
            c{1}, tree.text);
        throw(ME);
    end
    
end

