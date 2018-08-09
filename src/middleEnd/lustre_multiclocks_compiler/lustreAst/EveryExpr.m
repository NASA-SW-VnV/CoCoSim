classdef EveryExpr < LustreExpr
    %EveryExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        nodeName;
        nodeArgs;
        cond;
    end
    
    methods
        function obj = EveryExpr(nodeName, nodeArgs, cond)
            obj.nodeName = nodeName;
            obj.nodeArgs = nodeArgs;
            obj.cond = cond;
        end
        function new_obj = deepCopy(obj)
            %TODO: deepCopy nodeArgs
            new_obj = ContractModeExpr(obj.nodeName, ...
                obj.nodeArgs, obj.cond.deepCopy());
        end
        
        function code = print(obj, backend)
            if BackendType.isKIND2(backend)
                code = obj.print_kind2(backend);
            else
                %TODO: check if LUSTREC syntax is OK for the other backends.
                code = obj.print_lustrec(backend);
            end
        end
        
        function code = print_lustrec(obj, backend)
            args_str = NodeCallExpr.getArgsStr(obj.nodeArgs, backend);
            code = sprintf('(%s(%s) every %s)', ...
                obj.nodeName, ...
                args_str,...
                obj.cond.print(backend));
        end
        
        function code = print_kind2(obj, backend)
            args_str = NodeCallExpr.getArgsStr(obj.nodeArgs, backend);
            code = sprintf('(restart %s every %s)%s', ...
                obj.nodeName, ...
                obj.cond.print(backend),...
                args_str);
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

