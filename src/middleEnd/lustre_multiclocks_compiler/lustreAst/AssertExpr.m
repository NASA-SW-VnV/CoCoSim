classdef AssertExpr < LustreExpr
    %AssertExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        exp; %LustreExp
    end
    
    methods
        function obj = AssertExpr(exp)
            obj.exp = exp;
        end
        function new_obj = deepCopy(obj)
            new_obj = AssertExpr(obj.exp.deepCopy());
        end
        function code = print(obj, backend)
            %TODO: check if KIND2 syntax is OK for the other backends.
            code = obj.print_kind2(backend);
        end
        
        
        function code = print_lustrec(obj, backend)
            code = obj.print_kind2(backend);
        end
        function code = print_kind2(obj, backend)
            
            code = sprintf('assert %s;', ...
                obj.exp.print(backend));
            
        end
        function code = print_zustre(obj, backend)
            code = obj.print_kind2(backend);
        end
        function code = print_jkind(obj, backend)
            code = obj.print_kind2(backend);
        end
        function code = print_prelude(varargin)
            code = '';
        end
    end
    
end

