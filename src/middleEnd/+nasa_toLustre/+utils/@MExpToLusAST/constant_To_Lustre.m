function [code, exp_dt, dim] = constant_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    v = tree.value;
    exp_dt = args.expected_lusDT;
    dim = 1;
    if strcmp(args.expected_lusDT, 'real')
        code{1} = nasa_toLustre.lustreAst.RealExpr(str2double(v));
    elseif strcmp(args.expected_lusDT, 'bool')
        code{1} = nasa_toLustre.lustreAst.BooleanExpr(str2double(v));
    elseif strcmp(args.expected_lusDT, 'int')
        %tree might be 1 or 3e5
        code{1} = nasa_toLustre.lustreAst.IntExpr(str2double(v));
    else
        %isempty(expected_dt)
        if strcmp(tree.dataType, 'Integer')
            code{1} = nasa_toLustre.lustreAst.IntExpr(str2double(v));
            exp_dt = 'int';
        elseif strcmp(tree.dataType, 'Float')
            code{1} = nasa_toLustre.lustreAst.RealExpr(str2double(v));
            exp_dt = 'real';
        else
            % String | function_handle
            ME = MException('COCOSIM:TREE2CODE', ...
                'Expression "%s" of type "%s" is not handled in Block %s',...
                tree.text, tree_type, args.blk.Origin_path);
            throw(ME);
        end
    end
end
