function [code, exp_dt, dim] = binaryFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    tree_ID = tree.ID;
    expected_dt = args.expected_lusDT;
    switch tree_ID
        case {'or'}
            op = nasa_toLustre.lustreAst.BinaryExpr.OR;
            expected_dt = 'bool';
        case {'and'}
            op = nasa_toLustre.lustreAst.BinaryExpr.AND;
            expected_dt = 'bool';
        case {'xor'}
            op = nasa_toLustre.lustreAst.BinaryExpr.XOR;
            expected_dt = 'bool';
        case {'plus'}
            op = nasa_toLustre.lustreAst.BinaryExpr.PLUS;
        case {'minus'}
            op = nasa_toLustre.lustreAst.BinaryExpr.MINUS;
        otherwise
            ME = MException('COCOSIM:TREE2CODE', ...
                'Function "%s" is not handled in Block %s',...
                tree.ID, args.blk.Origin_path);
            throw(ME);
    end
    args.expected_lusDT = expected_dt;
    [code, exp_dt, dim] = nasa_toLustre.utils.MF2LusUtils.binaryFun_To_Lustre(...
        tree, args, op);
    
end