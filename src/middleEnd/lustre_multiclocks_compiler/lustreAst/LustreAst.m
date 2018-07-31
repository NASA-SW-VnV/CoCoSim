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
        % Given many args, this function return the binary operation
        % applied on all arguments.
        function exp = BinaryMultiArgs(op, args)
            if isempty(args) || numel(args) == 1
                exp = args;
            elseif numel(args) == 2
                exp = BinaryExpr(op, ...
                    args{1}, ...
                    args{2});
            else
                exp = BinaryExpr(op, ...
                    args{1}, ...
                    LustreAst.BinaryMultiArgs(op, args(2:end)));
            end
        end
    end
end

