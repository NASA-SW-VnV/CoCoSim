function code = print_kind2(obj, backend)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    require = {};
    for j=1:numel(obj.requires)
        require{j} = sprintf('%s', ...
            obj.requires{j}.print(backend));
    end
    require = MatlabUtils.strjoin(require, '');

    ensure = {};
    for j=1:numel(obj.ensures)
        ensure{j} = sprintf('%s', ...
            obj.ensures{j}.print(backend));
    end
    ensure = MatlabUtils.strjoin(ensure, '');
    code = sprintf('\tmode %s(\n%s%s\t);\n', obj.name, require, ensure);
end
