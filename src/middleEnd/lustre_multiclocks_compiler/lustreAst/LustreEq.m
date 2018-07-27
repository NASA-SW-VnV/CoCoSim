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
            obj.rhs = rhs;
            obj.lhs = lhs;
        end
        function code = print_lustrec(obj)
            if numel(obj.lhs) > 1
                lhs_cell = cellfun(@(x) {x.print_lustrec()}, obj.lhs, 'UniformOutput', 0);
                lhs_str = sprintf('(%s)', ...
                    MatlabUtils.strjoin(lhs_cell, ', '));
            else
                lhs_str = obj.lhs.print_lustrec();
            end
            rhs_str = obj.rhs.print_lustrec();
            code = sprintf('%s = %s;', lhs_str, rhs_str);
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

