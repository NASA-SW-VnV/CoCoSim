function new_obj = deepCopy(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    new_inputs = cellfun(@(x) x.deepCopy(), obj.inputs, ...
        'UniformOutput', 0);
    
    new_outputs = cellfun(@(x) x.deepCopy(), obj.outputs,...
        'UniformOutput', 0);
    
    new_localVars = cellfun(@(x) x.deepCopy(), obj.localVars, ...
        'UniformOutput', 0);
    
    new_localEqs = cellfun(@(x) x.deepCopy(), obj.bodyEqs, ...
        'UniformOutput', 0);
    
    new_obj = nasa_toLustre.lustreAst.LustreContract(obj.metaInfo, obj.name,...
        new_inputs, ...
        new_outputs, new_localVars, new_localEqs, ...
        obj.islocalContract);
end
