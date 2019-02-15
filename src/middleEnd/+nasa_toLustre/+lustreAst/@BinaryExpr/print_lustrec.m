function code = print_lustrec(obj, backend)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.*
    if obj.addEpsilon ...
            && (isequal(obj.op, '>=') || isequal(obj.op, '>') ...
            || isequal(obj.op, '<=') || isequal(obj.op, '<'))
        if isequal(obj.op, '>=') || isequal(obj.op, '<=')
            epsilonOp = BinaryExpr.LTE;
            and_or = 'or';
        else
            epsilonOp = BinaryExpr.GT;
            and_or = 'and';
        end
        if isempty(obj.epsilon)
            if isa(obj.left, 'RealExpr')
                obj.epsilon = eps(obj.left.getValue());
            elseif isa(obj.right, 'RealExpr')
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
        code = sprintf('(%s) %s (%s)', ...
            obj.left.print(backend),...
            obj.op, ...
            obj.right.print(backend));
        if obj.withPar
            code = sprintf('(%s)', code);
        end
    end
end
