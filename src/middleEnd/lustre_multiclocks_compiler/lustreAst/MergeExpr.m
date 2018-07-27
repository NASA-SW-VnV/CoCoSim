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
        function code = print_lustrec(obj)
            if numel(obj.exprs) > 1
                exprs_cell = cellfun(@(x) {sprintf('(%s)', x.print_lustrec())},...
                    obj.exprs, 'UniformOutput', 0);
                exprs_str = MatlabUtils.strjoin(exprs_cell, '\n\t\t');
            else
                exprs_str = obj.exprs.print_lustrec();
            end
            code = sprintf('(merge %s\n\t\t %s)', obj.clock.print_lustrec(), exprs_str);
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec();
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec();
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec();
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec();
        end
    end

end

