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
        
        function new_obj = deepCopy(obj)
            if iscell(obj.lhs)
                new_lhs = cellfun(@(x) x.deepCopy(), obj.lhs, 'UniformOutput', 0);
            else
                new_lhs = obj.lhs.deepCopy();
            end
            if iscell(obj.rhs)
                new_rhs = cellfun(@(x) x.deepCopy(), obj.rhs, 'UniformOutput', 0);
            else
                new_rhs = obj.rhs.deepCopy();
            end
            new_obj = LustreEq(new_lhs, new_rhs);
        end
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        
        function code = print_lustrec(obj, backend)
            if iscell(obj.lhs)
                lhs_cell = cellfun(@(x) x.print(backend), obj.lhs, 'UniformOutput', 0);
                lhs_str = sprintf('(%s)', ...
                    MatlabUtils.strjoin(lhs_cell, ', '));
            else
                lhs_str = obj.lhs.print(backend);
            end
            if iscell(obj.rhs)
                rhs_str = obj.rhs{1}.print(backend);
            else
                rhs_str = obj.rhs.print(backend);
            end
            
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

