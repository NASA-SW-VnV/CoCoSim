function new_obj = simplify(obj)

    new_states = cell(1, numel(obj.states));
    for i=1:numel(obj.states)
        new_states{i} = obj.states{i}.simplify();
    end
    new_obj = nasa_toLustre.lustreAst.LustreAutomaton(obj.name,...
        new_states);
end
