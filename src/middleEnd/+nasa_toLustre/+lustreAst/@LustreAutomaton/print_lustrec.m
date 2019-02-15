function code = print_lustrec(obj, backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    lines = {};
    lines{1} = sprintf('automaton %s\n', obj.name);
    % Strong transition
    for i=1:numel(obj.states)
        lines{end+1} = sprintf('%s\n', ...
            obj.states{i}.print(backend));
    end
    code = MatlabUtils.strjoin(lines, '');
end
