function new_obj = simplify(obj)

    display_msg('Start Optimizing Lustre code.', MsgType.INFO, 'LustreProgram.simplify', '');
    new_nodes = cellfun(@(x) x.simplify(), obj.nodes, ...
        'UniformOutput', 0);
    new_contracts = cellfun(@(x) x.simplify(), obj.contracts,...
        'UniformOutput', 0);
    new_obj = nasa_toLustre.lustreAst.LustreProgram(obj.opens, obj.types, new_nodes, new_contracts);
end
