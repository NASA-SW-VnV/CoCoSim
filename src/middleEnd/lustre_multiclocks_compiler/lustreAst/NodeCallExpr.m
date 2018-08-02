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
        
        function args = getArgs(obj)
            args = obj.args;
        end
        function  setArgs(obj, arg)
            obj.args = arg;
        end
        
        
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            
            code = sprintf('%s(%s)', ...
                obj.nodeName, ...
                NodeCallExpr.getArgsStr(obj.args, backend));
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
    
    methods(Static)
        function args_str = getArgsStr(args, backend)
            if numel(args) > 1 || iscell(args)
                args_cell = cellfun(@(x) x.print(backend), args, 'UniformOutput', 0);
                args_str = MatlabUtils.strjoin(args_cell, ', ');
            elseif numel(args) == 1
                args_str = args.print(backend);
            else
                args_str = '';
            end
        end
    end
end

