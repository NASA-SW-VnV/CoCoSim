
function v_lus = getAstValue(v, dt)
    % in this block, the output dataType is Boolean or double
    if strcmp(dt, 'bool')
        v_lus = BooleanExpr(v);
    else
        v_lus = RealExpr(v);
    end

end


