classdef ContractImportExpr < LustreExpr
    %ContractImportExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        name; %String
        inputs;
        outputs;
    end
    
    methods
        function obj = ContractImportExpr(name, inputs, outputs)
            obj.name = name;
            obj.inputs = inputs;
            obj.outputs = outputs;
        end
        function new_obj = deepCopy(obj)
            %TODO: deepCopy inputs and outputs
            new_obj = ContractImportExpr(obj.name, ...
                obj.inputs, obj.outputs);
        end
        
        function code = print(obj, backend)
            %TODO: check if KIND2 syntax is OK for the other backends.
            code = obj.print_kind2(backend);
        end
        
        
        function code = print_lustrec(obj)
            code = '';
        end
        function code = print_kind2(obj, backend)
            inputs_cell = cellfun(@(x) {x.print(backend)}, obj.inputs, 'UniformOutput', 0);
            inputs_str = MatlabUtils.strjoin(inputs_cell, ', ');
            outputs_cell = cellfun(@(x) {x.print(backend)}, obj.outputs, 'UniformOutput', 0);
            outputs_str = MatlabUtils.strjoin(outputs_cell, ', ');
            code = sprintf('import %s(%S) returns (%s);', ...
                obj.name, inputs_str, outputs_str );
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

