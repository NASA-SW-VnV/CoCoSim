function new_assignements = addInnerCond(lus_eqts, isInnerLusVar, orig_exp, state)
    import nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils
    import nasa_toLustre.lustreAst.*
    new_assignements = cell(numel(lus_eqts), 1);
    for i=1:numel(lus_eqts)
        if isa(lus_eqts{i}, 'ConcurrentAssignments')
            assignments = lus_eqts{i}.getAssignments();
            new_assignements_i = SF2LusUtils.addInnerCond(assignments, isInnerLusVar, orig_exp, state);
            new_assignements{i} = ConcurrentAssignments(new_assignements_i);
        elseif isa(lus_eqts{i}, 'LustreEq')
            new_assignements{i} = LustreEq(lus_eqts{i}.getLhs(), ...
                IteExpr(UnaryExpr(UnaryExpr.NOT, isInnerLusVar), ...
                lus_eqts{i}.getRhs(), lus_eqts{i}.getLhs()));
            
        elseif ~isempty(lus_eqts{i})
            display_msg(sprintf(...
                'Action "%s" in state %s should be an assignement (e.g. outputs = f(inputs))',...
                orig_exp, state.Origin_path), MsgType.ERROR, 'write_entry_action', '');
            break;
        end
    end
end