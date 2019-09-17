function [code, exp_dt, dim, extra_code] = colonExpression_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    extra_code = {};
    if count(tree.text, ':') == 2
        if strcmp(tree.leftExp.leftExp.type, 'constant') && strcmp(tree.leftExp.rightExp.type, 'constant') && strcmp(tree.rightExp.type, 'constant')
            [left, left_dt, ~, left_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.leftExp.leftExp, args);
            [middle, middle_dt, ~, middle_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.leftExp.rightExp, args);
            [right, right_dt, ~, right_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                tree.rightExp, args);
            extra_code = MatlabUtils.concat(left_extra_code, middle_extra_code, right_extra_code);

            upper_dt = nasa_toLustre.utils.MExpToLusDT.upperDT(left_dt, right_dt);
            exp_dt = nasa_toLustre.utils.MExpToLusDT.upperDT(upper_dt, middle_dt);
            left_value = left{1}.value;
            middle_value = middle{1}.value;
            right_value = right{1}.value;
            if strcmp(exp_dt, 'int')
                code = arrayfun(@(x) nasa_toLustre.lustreAst.IntExpr(x), (left_value:middle_value:right_value), 'UniformOutput', 0);
            else
                code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(x), (left_value:middle_value:right_value), 'UniformOutput', 0);
            end
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Expression "%s" only support constant input',...
                tree.text);
            throw(ME);
        end
        
    elseif count(tree.text, ':') == 1
        if ~isfield(tree, 'leftExp') && ~isfield(tree, 'rightExp')
            t = MatlabUtils.getExpTree('u(1:end)');
            tree = t.parameters(1);
        end
        c = symvar(tree.text);
        if isempty(c) || (length(c) == 1 && strcmp(c{1}, 'end'))
            try
                [code, exp_dt, dim] = nasa_toLustre.utils.MF2LusUtils.numFun_To_Lustre(...
                    tree, args);
            catch
                [left, left_dt, ~, left_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    tree.leftExp, args);
                [right, right_dt, ~, right_extra_code] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(...
                    tree.rightExp, args);
                extra_code = MatlabUtils.concat(left_extra_code, right_extra_code);

                exp_dt = nasa_toLustre.utils.MExpToLusDT.upperDT(left_dt, right_dt);
                if isa(left{1}, 'nasa_toLustre.lustreAst.IntExpr') || ...
                        isa(left{1}, 'nasa_toLustre.lustreAst.RealExpr')
                    left_value = left{1}.value;
                else
                    try
                        left_value = eval(left{1}.print(LusBackendType.LUSTREC));
                    catch
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Expression "%s" only support constant input',...
                            tree.text);
                        throw(ME);
                    end
                end
                if isa(right{1}, 'nasa_toLustre.lustreAst.IntExpr') || ...
                        isa(right{1}, 'nasa_toLustre.lustreAst.RealExpr')
                    right_value = right{1}.value;
                else
                    try
                        right_value = eval(right{1}.print(LusBackendType.LUSTREC));
                    catch
                        ME = MException('COCOSIM:TREE2CODE', ...
                            'Expression "%s" only support constant input',...
                            tree.text);
                        throw(ME);
                    end
                end
                if strcmp(exp_dt, 'int')
                    code = arrayfun(@(x) nasa_toLustre.lustreAst.IntExpr(x), (left_value:right_value), 'UniformOutput', 0);
                else
                    code = arrayfun(@(x) nasa_toLustre.lustreAst.RealExpr(x), (left_value:right_value), 'UniformOutput', 0);
                end
            end
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Using variable "%s" in expression "%s" is not supported.',...
                c{1}, tree.text);
            throw(ME);
        end
    else
        ME = MException('COCOSIM:TREE2CODE', ...
            'Expression "%s" is not supported.',...
            tree.text);
        throw(ME);
    end
    dim = [1 numel(code)];
end

