classdef LustreAst < handle
    %LustreAst
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods (Abstract)
        deepCopy(obj)
        changeArrowExp(obj, cond)
        print(obj, backend)
        print_lustrec(obj)
        print_kind2(obj)
        print_zustre(obj)
        print_jkind(obj)
        print_prelude(obj)
    end
    methods(Static)
        function code = listVarsWithDT(vars, backend)
            if iscell(vars)
                vars_code = cellfun(@(x) x.print(backend), vars, 'UniformOutput', 0);
                code = MatlabUtils.strjoin(vars_code, '\n\t');
            else
                code = vars.print(backend);
            end
        end
        
    end
end

