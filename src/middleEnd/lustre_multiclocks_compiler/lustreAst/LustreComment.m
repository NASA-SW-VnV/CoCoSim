classdef LustreComment < LustreExpr
    %LustreComment
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        text;
        isMultiLine;
    end
    
    methods 
        function obj = LustreComment(text, isMultiLine)
            obj.text = text;
            obj.isMultiLine = isMultiLine;
        end
        function code = print(obj, backend)
            code = obj.print_lustrec(backend);
        end
        function code = print_lustrec(obj, ~)
            if isempty(obj.text)
                return;
            end
            if obj.isMultiLine
                code = sprintf('(*\n%s\n*)', ...
                    obj.text);
            else
                code = sprintf('--%s', ...
                    obj.text);
            end
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

