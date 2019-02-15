function exp = nestedIteExpr(conds, thens)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    if numel(thens) ~= numel(conds) + 1
        display_msg('Number of Thens expressions should be equal to Numbers of Conds + 1',...
            MsgType.ERROR, 'IteExpr.nestedIteExpr', '');
        exp = nasa_toLustre.lustreAst.VarIdExpr('');
        return;
    end
    if isempty(conds)
        exp = thens;
    elseif numel(conds) == 1
        if iscell(conds)
            c = conds{1};
        else
            c = conds;
        end
        exp = nasa_toLustre.lustreAst.IteExpr(c, thens{1}, thens{2});
    else
        exp = nasa_toLustre.lustreAst.IteExpr(conds{1}, ...
            thens{1}, ...
            nasa_toLustre.lustreAst.IteExpr.nestedIteExpr( conds(2:end), thens(2:end)) ...
            );
    end
end
