function code = print_lustrec(obj, backend)

    lines = {};
    lines{1} = sprintf('automaton %s\n', obj.name);
    % Strong transition
    for i=1:numel(obj.states)
        lines{end+1} = sprintf('%s\n', ...
            obj.states{i}.print(backend));
    end
    code = MatlabUtils.strjoin(lines, '');
end
