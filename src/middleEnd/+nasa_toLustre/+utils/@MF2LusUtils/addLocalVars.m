function vars = addLocalVars(args, exp_dt, n)
    vars = {};
    slx_dt = LusValidateUtils.get_slx_dt(exp_dt);
    for i=1:n
        v_name = sprintf('cocosim_localVar_%s_%d', exp_dt, i);
        args.data_map(v_name) = struct('Name', v_name, 'LusDatatype', exp_dt, 'DataType', slx_dt, ...
            'CompiledType', slx_dt, 'InitialValue', '0', ...
            'ArraySize', '1 1', 'CompiledSize', '1 1', 'Scope', 'Local', ...
            'Port', '1');
        vars{end+1} = nasa_toLustre.lustreAst.VarIdExpr(v_name);
    end
end

