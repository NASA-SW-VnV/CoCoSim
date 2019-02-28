function code = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    lines = {};
    lines{1} = sprintf('\tstate %s:\n', obj.name);
    % Strong transition
    for i=1:numel(obj.strongTrans)
        lines{end+1} = sprintf('\tunless %s', ...
            obj.strongTrans{i}.print(backend));
    end
    %local variables
    if ~isempty(obj.local_vars)
        lines{end + 1} = sprintf('var %s\n', ...
            nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.local_vars, backend));
    end
    % body
    lines{end+1} = sprintf('\tlet\n');
    for i=1:numel(obj.body)
        lines{end+1} = sprintf('\t\t%s\n', ...
            obj.body{i}.print(backend));
    end
    lines{end+1} = sprintf('\ttel\n');
    % weak transition
    for i=1:numel(obj.weakTrans)
        lines{end+1} = sprintf('\tuntil %s\n', ...
            obj.weakTrans{i}.print(backend));
    end
    code = MatlabUtils.strjoin(lines, '');
end
