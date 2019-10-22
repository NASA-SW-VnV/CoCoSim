%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function code = print_preludeImportedNode(obj)
    lines = {};
    backend = LusBackendType.PRELUDE;
    %% metaInfo
    if ~isempty(obj.metaInfo)
        if ischar(obj.metaInfo)
            lines{end + 1} = sprintf('--%s\n',...
                strrep(obj.metaInfo, newline, '--'));
        else
            lines{end + 1} = obj.metaInfo.print(backend);
        end
    end
    nodeName = obj.name;
    %PRELUDE does not support "_" in the begining of the word.
    if MatlabUtils.startsWith(nodeName, '_')
        nodeName = sprintf('x%s', nodeName);
    end
    lines{end + 1} = sprintf('imported node %s(%s)\nreturns(%s) wcet 1;\n', ...
        nodeName, ...
        nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.inputs, backend, true), ...
        nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.outputs, backend, true));
    
    code = MatlabUtils.strjoin(lines, '');
end
