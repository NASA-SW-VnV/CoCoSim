function new_obj = deepCopy(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_types = cellfun(@(x) x.deepCopy(), obj.types,...
        'UniformOutput', 0);
    new_nodes = cellfun(@(x) x.deepCopy(), obj.nodes, ...
        'UniformOutput', 0);
    new_contracts = cellfun(@(x) x.deepCopy(), obj.contracts,...
        'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.LustreProgram(obj.opens, new_types, new_nodes, new_contracts);
end
