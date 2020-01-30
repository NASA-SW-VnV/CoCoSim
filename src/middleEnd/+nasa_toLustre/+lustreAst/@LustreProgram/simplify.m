function new_obj = simplify(obj)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    display_msg('Start Optimizing Lustre code.', MsgType.INFO, 'LustreProgram.simplify', '');
    new_nodes = cellfun(@(x) x.simplify(), obj.nodes, ...
        'UniformOutput', 0);
    new_contracts = cellfun(@(x) x.simplify(), obj.contracts,...
        'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.LustreProgram(obj.opens, obj.types, new_nodes, new_contracts);
end
