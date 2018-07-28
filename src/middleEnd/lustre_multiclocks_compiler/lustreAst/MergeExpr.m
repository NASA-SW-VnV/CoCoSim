classdef MergeExpr < LustreExpr
    %MergeExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        clock;%LusID
        exprs;
    end
    
    methods 
        function obj = MergeExpr(clock, exprs)
            obj.clock = clock;
            obj.exprs = exprs;
        end
        
        
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            if numel(obj.exprs) > 1
                exprs_cell = cellfun(@(x) {sprintf('(%s)', x.print(backend))},...
                    obj.exprs, 'UniformOutput', 0);
                exprs_str = MatlabUtils.strjoin(exprs_cell, '\n\t\t');
            else
                exprs_str = obj.exprs.print(backend);
            end
            code = sprintf('(merge %s\n\t\t %s)', obj.clock.print(backend), exprs_str);
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

