function code = print_lustrec(obj, backend) 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    if obj.withPar
        code = sprintf('(%s (%s))', ...
            obj.op, ...
            obj.expr.print(backend));
    else
        code = sprintf('%s (%s)', ...
            obj.op, ...
            obj.expr.print(backend));
    end
end
