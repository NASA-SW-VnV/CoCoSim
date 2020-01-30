function new_obj = simplify(obj)

    
%     if isnumeric(obj.value) && obj.value < 0
%         % -1 => -(1)
%         new_obj = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, nasa_toLustre.lustreAst.IntExpr(-double(obj.value)));
%     else
        new_obj = obj;
%     end
end
