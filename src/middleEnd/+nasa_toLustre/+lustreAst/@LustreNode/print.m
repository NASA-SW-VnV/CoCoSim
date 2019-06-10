%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function code = print(obj, backend)
    
    lines = {};
    if ~isempty(obj.metaInfo)
        if ischar(obj.metaInfo)
            lines{end + 1} = sprintf('(*\n%s\n*)\n',...
                obj.metaInfo);
        else
            lines{end + 1} = obj.metaInfo.print(backend);
        end
    end
    if obj.isImported
        isImported_str = 'imported';
    else
        isImported_str = '';
    end
    lines{end + 1} = sprintf('node %s %s(%s)\nreturns(%s);\n', ...
        isImported_str, ...
        obj.name, ...
        nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.inputs, backend, true), ...
        nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.outputs, backend, true));
    if ~isempty(obj.localContract)
        lines{end + 1} = obj.localContract.print(backend);
    end

    if obj.isImported
        code = MatlabUtils.strjoin(lines, '');
        return;
    end

    if ~isempty(obj.localVars)
        lines{end + 1} = sprintf('var %s\n', ...
            nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.localVars, backend));
    end
    lines{end+1} = sprintf('let\n');
    % local Eqs
    for i=1:numel(obj.bodyEqs)
        eq = obj.bodyEqs{i};
        if isempty(eq)
            continue;
        end
        lines{end+1} = sprintf('\t%s\n', ...
            eq.print(backend));

    end
    lines{end+1} = sprintf('tel\n');
    code = MatlabUtils.strjoin(lines, '');
end
