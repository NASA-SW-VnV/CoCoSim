function args_str = getArgsStr(args, backend)

    %             try
    if numel(args) > 1 || iscell(args)
        if numel(args) >= 1 && iscell(args{1})
            args_cell = cellfun(@(x) x{1}.print(backend), args, 'UniformOutput', 0);
        else
            args_cell = cellfun(@(x) x.print(backend), args, 'UniformOutput', 0);
        end
        args_str = MatlabUtils.strjoin(args_cell, ', ');
    elseif numel(args) == 1
        args_str = args.print(backend);
    else
        args_str = '';
    end
    %             catch me
    %                 me
    %             end
end
