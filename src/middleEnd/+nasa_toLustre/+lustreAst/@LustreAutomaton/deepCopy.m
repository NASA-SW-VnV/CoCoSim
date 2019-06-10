function new_obj = deepCopy(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_states = cell(1, numel(obj.states));
    for i=1:numel(obj.states)
        new_states{i} = obj.states{i}.deepCopy();
    end
    new_obj = nasa_toLustre.lustreAst.LustreAutomaton(obj.name,...
        new_states);
end
