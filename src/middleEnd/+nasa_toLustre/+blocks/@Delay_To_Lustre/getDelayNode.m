
function [delay_node] = getDelayNode(node_name, ...
        u_DT, delayLength, isDelayVariable, isReset, isEnabel)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    %node header
    [ u_DT, zero ] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( u_DT);
    node_inputs{1} = LustreVar('u', u_DT);
    node_inputs{2} = LustreVar('x0', u_DT);
    if isDelayVariable
        node_inputs{end + 1} = LustreVar('d', 'int');
    end
    if isReset
        node_inputs{end + 1} = LustreVar('reset', 'bool');
    end
    if isEnabel
        node_inputs{end + 1} = LustreVar('enable', 'bool');
    end


    pre_u_conds = {};
    pre_u_thens = {};
    if isDelayVariable
        pre_u_conds{end + 1} = BinaryExpr(BinaryExpr.LT, ...
            VarIdExpr('d'), IntExpr(1));
        pre_u_thens{end + 1} = VarIdExpr('u');
        pre_u_conds{end + 1} = BinaryExpr(BinaryExpr.GT, ...
            VarIdExpr('d'), IntExpr(delayLength));
        pre_u_thens{end + 1} = VarIdExpr('pre_u1');
    end
    variables = cell(1, delayLength);
    body = cell(1, delayLength + 1 );
    for i=1:delayLength
        pre_u_i = sprintf('pre_u%d', i);
        if i< delayLength
            pre_u_i_plus_1 = sprintf('pre_u%d', i+1);
        else
            pre_u_i_plus_1 = 'u';
        end
        if isReset
            enable_then = IteExpr(...
                VarIdExpr('reset'), ...
                VarIdExpr('x0'),...
                UnaryExpr(UnaryExpr.PRE, ...
                            VarIdExpr(pre_u_i_plus_1)));
        else
            enable_then = UnaryExpr(UnaryExpr.PRE, ...
                VarIdExpr(pre_u_i_plus_1));
        end
        if isEnabel
            enable_else = BinaryExpr(...
                BinaryExpr.ARROW, ...
                zero, ...
                UnaryExpr(UnaryExpr.PRE, ...
                    VarIdExpr(pre_u_i)));
            enable = IteExpr(VarIdExpr('enable'), enable_then, enable_else);
        else
            enable = enable_then;
        end
        rhs = BinaryExpr(...
                BinaryExpr.ARROW, ...
                VarIdExpr('x0'), ...
                enable);
        body{i} = LustreEq(VarIdExpr(pre_u_i), rhs);

        if isDelayVariable
            j = delayLength - i + 1;
            pre_u_conds{end + 1} = BinaryExpr(BinaryExpr.EQ, ...
                VarIdExpr('d'), IntExpr(i));
            pre_u_thens{end+1} = VarIdExpr(sprintf('pre_u%d', j));
            %pre_u = sprintf('%s if d = %d then pre_u%d\n\t\telse', ...
            %    pre_u, i, j);
        end
        variables{i} = LustreVar(pre_u_i, u_DT);
    end
    if isDelayVariable
        pre_u_thens{end+1} = VarIdExpr('x0');
    else
        pre_u_thens{end+1} = VarIdExpr('pre_u1');
    end
    pre_u_rhs = IteExpr.nestedIteExpr(pre_u_conds, pre_u_thens);
    if isEnabel
        pre_u_rhs = IteExpr(...
            VarIdExpr('enable'), ...
            pre_u_rhs, ...
            BinaryExpr(...
                BinaryExpr.ARROW, ...
                zero, ...
                UnaryExpr(UnaryExpr.PRE, ...
                    VarIdExpr('pre_u'))));
    end
    pre_u = LustreEq(VarIdExpr('pre_u'), pre_u_rhs);
    body{delayLength + 1} = pre_u;
    outputs = LustreVar('pre_u', u_DT);
    delay_node = LustreNode({},...
        node_name, node_inputs, outputs, ...
        {}, variables, body, false);
    %node_header = sprintf('node %s(%s)\nreturns(pre_u:%s);\n',...
    %    node_name, node_inputs, u_DT);
    %sprintf('%s%slet\n\t%s%s\ntel',...
    %    node_header, vars, body, pre_u);
end

