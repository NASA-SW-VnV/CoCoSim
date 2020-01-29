function [code, exp_dt, dim, extra_code] = maxMinFun_To_Lustre(tree, args, op)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    if length(tree.parameters) > 1
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function "%s" in expression "%s" has more than 1 argument is not supported in block %s.',...
            tree.ID, tree.text, HtmlItem.addOpenCmd(args.blk.Origin_path));
        throw(ME);
    end
    if isfield(args, 'expected_dim')
        expected_dim = prod(args.expected_dim);
    else
        expected_dim = 1;
    end
    [x, x_dt, x_dim, extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1), args);
    if length(x_dim) > 1 && ~(x_dim(1) == 1 || x_dim(2) == 1)
        % max/min of a matrix
        %TODO
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function "%s" in expression "%s" for more than 2 dimension is not supported  in block %s.',...
            tree.ID, tree.text, HtmlItem.addOpenCmd(args.blk.Origin_path));
        throw(ME);
    elseif expected_dim <= 2
        % max/min of vector
        C =cell(1, length(x)-1);
        thens = cell(1, length(x));
        for i=1:length(x)-1
            C{i} = compare(x{i}, op, x(i+1:end));
            if expected_dim == 1
                thens{i} = x{i};
            else
                thens{i} = nasa_toLustre.lustreAst.TupleExpr(...
                    {x{i}, nasa_toLustre.lustreAst.RealExpr(i) });
            end
        end
        if expected_dim == 1
            thens{end} = x{end};
        else
            thens{end} = nasa_toLustre.lustreAst.TupleExpr(...
                {x{end}, nasa_toLustre.lustreAst.RealExpr(length(x)) });
        end
        exp = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(C, thens);
        exp_dt{1} = x_dt{1};
        exp_dt{2} = 'real';
        dim = 1;
        vars = nasa_toLustre.utils.MF2LusUtils.addLocalVars(args, x_dt{1}, 1);
        if expected_dim == 2
            vars(end+1) = nasa_toLustre.utils.MF2LusUtils.addLocalVars(args, 'real', 1);
            dim = 2;
        end
        extra_code{1} = nasa_toLustre.lustreAst.LustreEq(...
            nasa_toLustre.lustreAst.TupleExpr(vars), exp);
        code = vars;
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function "%s" in expression "%s" expecting more than 2 outputs is not supported in block %s.',...
            tree.ID, tree.text, HtmlItem.addOpenCmd(args.blk.Origin_path));
        throw(ME);
    end
end
    
function exp = compare(x1, op, x2_list)
C = cellfun(@(x) nasa_toLustre.lustreAst.BinaryExpr(op, x1, x), x2_list, 'UniformOutput', 0);
exp = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
    nasa_toLustre.lustreAst.BinaryExpr.AND, C);
end