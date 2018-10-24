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
            if iscell(obj.inputs)
                new_inputs = cellfun(@(x) x.deepCopy(), obj.inputs, 'UniformOutput', 0);
            else
                new_inputs = obj.inputs.deepCopy();
            end
            
            if iscell(obj.outputs)
                new_outputs = cellfun(@(x) x.deepCopy(), obj.outputs, 'UniformOutput', 0);
            else
                new_outputs = obj.outputs.deepCopy();
            end
            
            new_obj = ContractImportExpr(obj.name, ...
                new_inputs, new_outputs);
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        function new_obj = changeArrowExp(obj, ~)
            new_obj = obj;
        end
        
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                if iscell(objects)
                    for i=1:numel(objects)
                        nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                    end
                else
                    nodesCalled = [nodesCalled, objects.getNodesCalled()];
                end
            end
            addNodes(obj.inputs);
            addNodes(obj.outputs);
            nodesCalled{end+1} = obj.name;
        end
        
        %%
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
            inputs_str = NodeCallExpr.getArgsStr(obj.inputs, backend);
            outputs_str = NodeCallExpr.getArgsStr(obj.outputs, backend);
            code = sprintf('import %s(%s) returns (%s);', ...
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

