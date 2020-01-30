function new_obj = deepCopy(obj)

    new_states = cell(1, numel(obj.states));
    for i=1:numel(obj.states)
        new_states{i} = obj.states{i}.deepCopy();
    end
    new_obj = nasa_toLustre.lustreAst.LustreAutomaton(obj.name,...
        new_states);
end
