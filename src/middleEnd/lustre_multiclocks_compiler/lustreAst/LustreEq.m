classdef LustreEq < LustreAst
    %LustreEq
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        lhs;
        rhs;
    end
    
    methods 
        function obj = LustreEq(lhs, rhs)
            if ischar(rhs)
                obj.rhs = VarIdExpr(rhs);
            else
                obj.rhs = rhs;
            end
            obj.lhs = lhs;
        end
        
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        
        function code = print_lustrec(obj, backend)
            if numel(obj.lhs) > 1
                lhs_cell = cellfun(@(x) {x.print(backend)}, obj.lhs, 'UniformOutput', 0);
                lhs_str = sprintf('(%s)', ...
                    MatlabUtils.strjoin(lhs_cell, ', '));
            else
                lhs_str = obj.lhs.print(backend);
            end
            rhs_str = obj.rhs.print(backend);
            code = sprintf('%s = %s;', lhs_str, rhs_str);
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(BackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(BackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(BackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(BackendType.PRELUDE);
        end
    end

end

