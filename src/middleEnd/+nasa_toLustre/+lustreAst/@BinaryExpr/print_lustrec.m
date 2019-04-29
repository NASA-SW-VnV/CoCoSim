function code = print_lustrec(obj, backend)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if obj.addEpsilon ...
            && (strcmp(obj.op, '>=') || strcmp(obj.op, '>') ...
            || strcmp(obj.op, '<=') || strcmp(obj.op, '<'))
        if strcmp(obj.op, '>=') || strcmp(obj.op, '<=')
            epsilonOp = nasa_toLustre.lustreAst.BinaryExpr.LTE;
            and_or = 'or';
        else
            epsilonOp = nasa_toLustre.lustreAst.BinaryExpr.GT;
            and_or = 'and';
        end
        if isempty(obj.epsilon)
            if isa(obj.left, 'nasa_toLustre.lustreAst.RealExpr')
                obj.epsilon = eps(obj.left.getValue());
            elseif isa(obj.right, 'nasa_toLustre.lustreAst.RealExpr')
                obj.epsilon = eps(obj.right.getValue());
            else
                obj.epsilon = 1e-15;
            end
        end
        code = sprintf('((%s %s %s) %s abs_real(%s - %s) %s %.30f)', ...
            obj.left.print(backend),...
            obj.op, ...
            obj.right.print(backend), ...
            and_or, ...
            obj.left.print(backend),...
            obj.right.print(backend), ...
            epsilonOp, ...
            obj.epsilon);
    else
        code = sprintf('%s %s %s', ...
            obj.left.print(backend),...
            obj.op, ...
            obj.right.print(backend));
        if obj.withPar || strcmp(obj.op, '->')
            code = sprintf('(%s)', code);
        end
    end
end
