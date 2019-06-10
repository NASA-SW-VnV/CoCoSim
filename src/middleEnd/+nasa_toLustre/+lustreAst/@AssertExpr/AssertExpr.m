classdef AssertExpr < nasa_toLustre.lustreAst.PropertyExpr
    %AssertExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        function obj = AssertExpr(exp)
            obj = obj@nasa_toLustre.lustreAst.PropertyExpr('', exp);
        end
        new_obj = deepCopy(obj)
        code = print(obj, backend)
        code = print_lustrec(obj, backend)
        code = print_kind2(obj, backend)
        code = print_zustre(obj, backend)
        code = print_jkind(obj, backend)
        code = print_prelude(obj)
    end
    
end

