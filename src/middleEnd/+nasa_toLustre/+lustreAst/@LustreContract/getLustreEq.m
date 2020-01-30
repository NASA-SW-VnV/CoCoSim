function lines = getLustreEq(obj, lines, backend)

        for i=1:numel(obj.bodyEqs)
        eq = obj.bodyEqs{i};
        if ~isa(eq, 'nasa_toLustre.lustreAst.LustreEq')
            % assumptions, guarantees, modes...
            lines{end+1} = sprintf('\t%s\n', ...
                eq.print(backend));
            continue;
        end
        if numel(eq.lhs) > 1
            var = eq.lhs{1};
        else
            var = eq.lhs;
        end
        if ~isa(var, 'nasa_toLustre.lustreAst.LustreVar') && ~isa(var, 'nasa_toLustre.lustreAst.VarIdExpr')
            continue;
        end
        if isa(var, 'nasa_toLustre.lustreAst.LustreVar')
            varDT = var.getDT();
        else
            varDT = obj.getDT(obj.localVars, var.getId());
        end
        
        lines{end+1} = sprintf('\tvar %s : %s = %s;\n', ...
            var.getId(), varDT, eq.rhs.print(backend));
    end
end
