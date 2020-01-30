function transitions = getAllTransitions(SFContent)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
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
            nasa_toLustre.blocks.Chart_To_Lustre.getAllTransitions(SFContent.GraphicalFunctions{i})];
    end
end

