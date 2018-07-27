classdef BooleanExpr < LustreExpr
    %BooleanExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        value;
    end
   
    methods 
        function obj = BooleanExpr(v)
            obj.value = v;
        end
        
        
        function code = print_lustrec(obj)
            if isnumeric(obj.value)
                if obj.value ~= 0
                    code = 'true';
                else
                    code = 'false';
                end
            elseif ischar(obj.value)
                if isequal(obj.value, 'true') || isequal(obj.value, 'false')
                    code = obj.value;
                else
                    if str2num(obj.value) ~= 0
                        code = 'true';
                    else
                        code = 'false';
                    end
                end
            else
                display_msg(sprintf('%s is not a lustre boolean Expression', obj.value), ...
                    MsgType.ERROR, 'BooleanExpr', '');
                code = obj.value;
            end
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

