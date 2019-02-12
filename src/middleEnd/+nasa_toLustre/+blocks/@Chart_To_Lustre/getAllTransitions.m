
function transitions = getAllTransitions(SFContent)
    import nasa_toLustre.blocks.Chart_To_Lustre
    transitions = {};
    for i=1:numel(SFContent.States)
        transitions = [transitions, ...
            SFContent.States{i}.Composition.DefaultTransitions];
        transitions = [transitions, ...
            SFContent.States{i}.OuterTransitions];
        transitions = [transitions, ...
            SFContent.States{i}.InnerTransitions];
    end
    for i=1:numel(SFContent.Junctions)
        transitions = [transitions, ...
            SFContent.Junctions{i}.OuterTransitions];
    end
    for i=1:numel(SFContent.GraphicalFunctions)
        transitions = [transitions, ...
            Chart_To_Lustre.getAllTransitions(SFContent.GraphicalFunctions{i})];
    end
end

