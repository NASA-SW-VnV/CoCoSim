classdef ContractAssumeExpr < LustreExpr
    %ContractAssumeExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        id; %String
        exp; %LustreExp
    end
    
    methods
        function obj = ContractAssumeExpr(id, exp)
            obj.id = id;
            obj.exp = exp;
        end
        function new_obj = deepCopy(obj)
            new_obj = ContractAssumeExpr(obj.id, ...
                obj.exp.deepCopy());
        end
        function code = print(obj, backend)
            %TODO: check if KIND2 syntax is OK for the other backends.
            code = obj.print_kind2(backend);
        end
        
        
        function code = print_lustrec(obj)
            code = '';
        end
        function code = print_kind2(obj, backend)
            if isempty(obj.id)
                code = sprintf('assume %s;', ...
                    obj.exp.print(backend));
            else
                code = sprintf('assume "%s" %s;', ...
                    obj.id, ...
                    obj.exp.print(backend));
            end
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

