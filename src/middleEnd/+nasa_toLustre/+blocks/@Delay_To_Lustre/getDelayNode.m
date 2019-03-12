function [delay_node] = getDelayNode(node_name, ...
        u_DT, delayLength, isDelayVariable, isReset, isEnabel)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %node header
    [ u_DT, zero ] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( u_DT);
    node_inputs{1} = nasa_toLustre.lustreAst.LustreVar('u', u_DT);
    node_inputs{2} = nasa_toLustre.lustreAst.LustreVar('x0', u_DT);
    if isDelayVariable
        node_inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar('d', 'int');
    end
    if isReset
        node_inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar('reset', 'bool');
    end
    if isEnabel
        node_inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar('enable', 'bool');
    end


    pre_u_conds = {};
    pre_u_thens = {};
    if isDelayVariable
        pre_u_conds{end + 1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, ...
            nasa_toLustre.lustreAst.VarIdExpr('d'), nasa_toLustre.lustreAst.IntExpr(1));
        pre_u_thens{end + 1} = nasa_toLustre.lustreAst.VarIdExpr('u');
        pre_u_conds{end + 1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, ...
            nasa_toLustre.lustreAst.VarIdExpr('d'), nasa_toLustre.lustreAst.IntExpr(delayLength));
        pre_u_thens{end + 1} = nasa_toLustre.lustreAst.VarIdExpr('pre_u1');
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
            enable_then = nasa_toLustre.lustreAst.IteExpr(...
                nasa_toLustre.lustreAst.VarIdExpr('reset'), ...
                nasa_toLustre.lustreAst.VarIdExpr('x0'),...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                            nasa_toLustre.lustreAst.VarIdExpr(pre_u_i_plus_1)));
        else
            enable_then = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                nasa_toLustre.lustreAst.VarIdExpr(pre_u_i_plus_1));
        end
        if isEnabel
            enable_else = nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                zero, ...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                    nasa_toLustre.lustreAst.VarIdExpr(pre_u_i)));
            enable = nasa_toLustre.lustreAst.IteExpr(nasa_toLustre.lustreAst.VarIdExpr('enable'), enable_then, enable_else);
        else
            enable = enable_then;
        end
        rhs = nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                nasa_toLustre.lustreAst.VarIdExpr('x0'), ...
                enable);
        body{i} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(pre_u_i), rhs);

        if isDelayVariable
            j = delayLength - i + 1;
            pre_u_conds{end + 1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
                nasa_toLustre.lustreAst.VarIdExpr('d'), nasa_toLustre.lustreAst.IntExpr(i));
            pre_u_thens{end+1} = nasa_toLustre.lustreAst.VarIdExpr(sprintf('pre_u%d', j));
            %pre_u = sprintf('%s if d = %d then pre_u%d\n\t\telse', ...
            %    pre_u, i, j);
        end
        variables{i} = nasa_toLustre.lustreAst.LustreVar(pre_u_i, u_DT);
    end
    if isDelayVariable
        pre_u_thens{end+1} = nasa_toLustre.lustreAst.VarIdExpr('x0');
    else
        pre_u_thens{end+1} = nasa_toLustre.lustreAst.VarIdExpr('pre_u1');
    end
    pre_u_rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(pre_u_conds, pre_u_thens);
    if isEnabel
        pre_u_rhs = nasa_toLustre.lustreAst.IteExpr(...
            nasa_toLustre.lustreAst.VarIdExpr('enable'), ...
            pre_u_rhs, ...
            nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                zero, ...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                    nasa_toLustre.lustreAst.VarIdExpr('pre_u'))));
    end
    pre_u = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('pre_u'), pre_u_rhs);
    body{delayLength + 1} = pre_u;
    outputs = nasa_toLustre.lustreAst.LustreVar('pre_u', u_DT);
    delay_node = nasa_toLustre.lustreAst.LustreNode({},...
        node_name, node_inputs, outputs, ...
        {}, variables, body, false);
    %node_header = sprintf('node %s(%s)\nreturns(pre_u:%s);\n',...
    %    node_name, node_inputs, u_DT);
    %sprintf('%s%slet\n\t%s%s\ntel',...
    %    node_header, vars, body, pre_u);
end

