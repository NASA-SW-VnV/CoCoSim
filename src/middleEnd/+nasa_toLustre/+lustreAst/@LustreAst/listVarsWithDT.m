function code = listVarsWithDT(vars, backend, forNodeHeader)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin < 3
        forNodeHeader = false;
    end
    if iscell(vars)
        vars_code = cellfun(@(x) x.print(backend), vars, 'UniformOutput', 0);
        % put 5 variables per line
        n = length(vars_code);
        code = '';
        for i=1:5:n
            if n > i+4
                tmp = MatlabUtils.strjoin(vars_code(i:i+4), ' ');
            else
                tmp = MatlabUtils.strjoin(vars_code(i:end), ' ');
            end
            code = sprintf('%s\n\t%s', code, tmp);
        end
    else
        code = vars.print(backend);
    end
    % no ";" in the end of node inputs/outputs for PRELUDE and JKIND
    if forNodeHeader ...
            && (LusBackendType.isJKIND(backend) || LusBackendType.isPRELUDE(backend))...
            && MatlabUtils.endsWith(code, ';')
        code = code(1:end-1);
    end
end
