function [delay_node] = getDelayNode(node_name, ...
        u_DT, delayLength, isDelayVariable)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %node header
    [ u_DT, ~ ] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( u_DT);
    node_inputs{1} = nasa_toLustre.lustreAst.LustreVar('u', u_DT);
    node_inputs{2} = nasa_toLustre.lustreAst.LustreVar('x0', u_DT);
    if isDelayVariable
        node_inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar('d', 'int');
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
        enable_then = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
            nasa_toLustre.lustreAst.VarIdExpr(pre_u_i_plus_1));
        enable = enable_then;
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
            
        end
        variables{i} = nasa_toLustre.lustreAst.LustreVar(pre_u_i, u_DT);
    end
    if isDelayVariable
        pre_u_thens{end+1} = nasa_toLustre.lustreAst.VarIdExpr('x0');
    else
        pre_u_thens{end+1} = nasa_toLustre.lustreAst.VarIdExpr('pre_u1');
    end
    pre_u_rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(pre_u_conds, pre_u_thens);
    
    pre_u = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('pre_u'), pre_u_rhs);
    body{delayLength + 1} = pre_u;
    outputs = nasa_toLustre.lustreAst.LustreVar('pre_u', u_DT);
    delay_node = nasa_toLustre.lustreAst.LustreNode({},...
        node_name, node_inputs, outputs, ...
        {}, variables, body, false);
end

