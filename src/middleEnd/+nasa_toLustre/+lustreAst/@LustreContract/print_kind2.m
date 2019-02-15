function code = print_kind2(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    lines = {};
    if ~isempty(obj.metaInfo)
        if ischar(obj.metaInfo)
            lines{end + 1} = sprintf('(*\n%s\n*)\n',...
                obj.metaInfo);
        else
            lines{end + 1} = obj.metaInfo.print(backend);
        end
    end
    if obj.islocalContract
        lines{end+1} = '(*@contract\n';
        lines = obj.getLustreEq( lines, backend);
        lines{end+1} = '*)\n';
    else
        lines{end + 1} = sprintf('contract %s(%s)\nreturns(%s);\n', ...
            obj.name, ...
            LustreAst.listVarsWithDT(obj.inputs, backend), ...
            LustreAst.listVarsWithDT(obj.outputs, backend));
        lines{end+1} = 'let\n';
        % local Eqs
        lines = obj.getLustreEq( lines, backend);
        lines{end+1} = 'tel\n';
    end
    code = sprintf(MatlabUtils.strjoin(lines, ''));
end
