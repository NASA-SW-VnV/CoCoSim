classdef IteExpr < LustreExpr
    %IteExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        condition;
        thenExpr;
        ElseExpr;
    end
    
    methods 
        function obj = IteExpr(condition, thenExpr, ElseExpr)
            obj.condition = condition;
            obj.thenExpr = thenExpr;
            obj.ElseExpr = ElseExpr;
        end
        function code = print_lustrec(obj)
            code = sprintf('if %s then\n\t\t%s\n\t\telse %s', ...
                obj.condition.print_lustre(),...
                obj.thenExpr.print_lustre(), ...
                obj.ElseExpr.print_lustre());
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

