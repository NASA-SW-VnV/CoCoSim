classdef NodeCallExpr < LustreExpr
    %NodeCallExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        nodeName;
        args;
    end
    
    methods 
        function obj = NodeCallExpr(nodeName, args)
            obj.nodeName = nodeName;
            obj.args = args;
        end
        function code = print_lustrec(obj)
            if numel(obj.args) > 1
                args_cell = cellfun(@(x) {x.print_lustrec()}, obj.args, 'UniformOutput', 0);
                args_str = MatlabUtils.strjoin(args_cell, ', ');
            else
                args_str = obj.args.print_lustrec();
            end
            code = sprintf('%s(%s)', obj.nodeName, args_str);
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

