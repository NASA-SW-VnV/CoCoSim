classdef ContractGuaranteeExpr < LustreExpr
    %ContractGuaranteeExpr
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
        function obj = ContractGuaranteeExpr(id, exp)
            obj.id = id;
            obj.exp = exp;
        end
        function new_obj = deepCopy(obj)
            new_obj = ContractGuaranteeExpr(obj.id, ...
                obj.exp.deepCopy());
        end
        function code = print(obj, backend)
            if BackendType.isKIND2(backend)
                code = obj.print_kind2(backend);
            else
                code = '';
            end
        end
        
        
        function code = print_lustrec(obj)
            code = '';
        end
        function code = print_kind2(obj, backend)
            if isempty(obj.id)
                code = sprintf('guarantee %s;', ...
                    obj.exp.print(backend));
            else
                code = sprintf('guarantee "%s" %s;', ...
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

