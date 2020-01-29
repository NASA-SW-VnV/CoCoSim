function new_obj = deepCopy(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    new_local_vars = cellfun(@(x) x.deepCopy(), obj.local_vars, 'UniformOutput', 0);

    new_strongTrans = cellfun(@(x) x.deepCopy(), obj.strongTrans, 'UniformOutput', 0);

    new_weakTrans = cellfun(@(x) x.deepCopy(), obj.weakTrans, 'UniformOutput', 0);

    new_body = cellfun(@(x) x.deepCopy(), obj.body, 'UniformOutput', 0);

    new_obj = nasa_toLustre.lustreAst.AutomatonState(obj.name, new_local_vars, ...
        new_strongTrans, new_weakTrans, new_body);
end
