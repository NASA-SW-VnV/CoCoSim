function new_assignements = addInnerCond(lus_eqts, isInnerLusVar, orig_exp, state)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
        new_assignements = cell(numel(lus_eqts), 1);
    for i=1:numel(lus_eqts)
        if isa(lus_eqts{i}, 'nasa_toLustre.lustreAst.ConcurrentAssignments')
            assignments = lus_eqts{i}.getAssignments();
            new_assignements_i = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.addInnerCond(assignments, isInnerLusVar, orig_exp, state);
            new_assignements{i} = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignements_i);
        elseif isa(lus_eqts{i}, 'nasa_toLustre.lustreAst.LustreEq')
            new_assignements{i} = nasa_toLustre.lustreAst.LustreEq(lus_eqts{i}.getLhs(), ...
                nasa_toLustre.lustreAst.IteExpr(nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, isInnerLusVar), ...
                lus_eqts{i}.getRhs(), lus_eqts{i}.getLhs()));
            
        elseif ~isempty(lus_eqts{i})
            display_msg(sprintf(...
                'Action "%s" in state %s should be an assignement (e.g. outputs = f(inputs))',...
                orig_exp, state.Origin_path), MsgType.ERROR, 'write_entry_action', '');
            break;
        end
    end
end
