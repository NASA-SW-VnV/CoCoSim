classdef LustreContract < LustreAst
    %LustreContract
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        metaInfo;%String
        name; %String
        inputs; %list of Vars
        outputs;
        localVars;
        bodyEqs;
        islocalContract;
    end
    
    methods
        function obj = LustreContract(metaInfo, name, inputs, ...
                outputs, localVars, bodyEqs, islocalContract)
            if nargin == 0
                obj.metaInfo = '';
                obj.name = '';
                obj.inputs = {};
                obj.outputs = {};
                obj.localVars = {};
                obj.bodyEqs = {};
                obj.islocalContract = 1;
            else
                obj.metaInfo = metaInfo;
                obj.name = name;
                obj.setInputs(inputs);
                obj.setOutputs(outputs);
                obj.setLocalVars(localVars);
                obj.setBodyEqs(bodyEqs);
                obj.islocalContract = islocalContract;
            end
        end
        %%
        function setMetaInfo(obj, metaInfo)
            obj.metaInfo = metaInfo;
        end
        function setName(obj, name)
            obj.name = name;
        end
        function name = getName(obj)
            name = obj.name;
        end
        function inputs = getInputs(obj)
            inputs = obj.inputs;
        end
        function setInputs(obj, inputs)
            if ~iscell(inputs) && numel(inputs) == 1
                obj.inputs{1} = inputs;
            else
                obj.inputs = inputs;
            end
        end
        function outputs = getOutputs(obj)
            outputs = obj.outputs;
        end
        function setOutputs(obj, outputs)
            if ~iscell(outputs) && numel(outputs) == 1
                obj.outputs{1} = outputs;
            else
                obj.outputs = outputs;
            end
        end
        
        function setLocalVars(obj, localVars)
            if ~iscell(localVars) && numel(localVars) == 1
                obj.localVars{1} = localVars;
            else
                obj.localVars = localVars;
            end
        end
        function addVar(obj, v)
            obj.localVars{end+1} = v;
        end
        function setBodyEqs(obj, bodyEqs)
            if ~iscell(bodyEqs)
                obj.bodyEqs{1} = bodyEqs;
            else
                obj.bodyEqs = bodyEqs;
            end
        end
        function addLocalEqs(obj, eq)
            obj.bodyEqs{end+1} = eq;
        end
        
        %%
        function dt = getDT(obj, localVars, varID)
            dt = '';
            for i=1:numel(localVars)
                if isequal(localVars{i}.getId(), varID)
                    dt = localVars{i}.type;
                    break;
                end
            end
        end
        %%
        function new_obj = deepCopy(obj)
            new_inputs = cellfun(@(x) x.deepCopy(), obj.inputs, ...
                'UniformOutput', 0);
            
            new_outputs = cellfun(@(x) x.deepCopy(), obj.outputs,...
                'UniformOutput', 0);
            
            new_localVars = cellfun(@(x) x.deepCopy(), obj.localVars, ...
                'UniformOutput', 0);
            
            new_localEqs = cellfun(@(x) x.deepCopy(), obj.bodyEqs, ...
                'UniformOutput', 0);
            
            new_obj = LustreContract(obj.metaInfo, obj.name,...
                new_inputs, ...
                new_outputs, new_localVars, new_localEqs, ...
                obj.islocalContract);
        end
        
        %% simplify expression
        function new_obj = simplify(obj)
            new_obj = obj.substituteVars();
            new_localEqs = cellfun(@(x) x.simplify(), new_obj.bodyEqs, ...
                'UniformOutput', 0);
            new_obj.setBodyEqs(new_localEqs);
        end
        
        %% nbOccuranceVar
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.bodyEqs, 'UniformOutput', true);
            nb_occ = sum(nb_occ_perEq);
        end
        
         %% substituteVars 
        function new_obj = substituteVars(obj)
            new_obj = LustreNode.contractNode_substituteVars(obj);
        end
        
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            new_obj = obj;
            varIds = {};
        end
        function new_obj = changeArrowExp(obj, ~)
            new_obj = obj;
        end
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            if obj.islocalContract
                %Only import contracts are supported for the moment.
                for i=1:numel(obj.bodyEqs)
                    if isa(obj.bodyEqs{i}, 'ContractImportExpr')
                        [obj.bodyEqs{i}, outputs_map] = ...
                            obj.bodyEqs{i}.pseudoCode2Lustre(outputs_map);
                    end
                end
                new_obj = obj;
            else
                %it is not used by stateflow.
                new_obj = obj;
            end
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                for i=1:numel(objects)
                    nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
                end
            end
            addNodes(obj.bodyEqs);
        end
        
        
        
        %%
        function code = print(obj, backend)
            if LusBackendType.isKIND2(backend)
                code = obj.print_kind2(backend);
            else
                code = '';
            end
        end
        
        function code = print_lustrec(obj)
            code = '';
        end
        
        function code = print_kind2(obj, backend)
            lines = {};
            if ~isempty(obj.metaInfo)
                if ischar(obj.metaInfo)
                    lines{end + 1} = sprintf('(*\n%s\n*)\n',...
                        obj.metaInfo);
                else
                    lines{end + 1} = obj.metaInfo.print(backend);
                end
            end
            if obj.islocalContract
                lines{end+1} = '(*@contract\n';
                lines = obj.getLustreEq( lines, backend);
                lines{end+1} = '*)\n';
            else
                lines{end + 1} = sprintf('contract %s(%s)\nreturns(%s);\n', ...
                    obj.name, ...
                    LustreAst.listVarsWithDT(obj.inputs, backend), ...
                    LustreAst.listVarsWithDT(obj.outputs, backend));
                lines{end+1} = 'let\n';
                % local Eqs
                lines = obj.getLustreEq( lines, backend);
                lines{end+1} = 'tel\n';
            end
            code = sprintf(MatlabUtils.strjoin(lines, ''));
        end
        function code = print_zustre(obj)
            code = '';
        end
        function code = print_jkind(obj)
            code = '';
        end
        function code = print_prelude(obj)
            code = '';
        end
        
        %% utils
        function lines = getLustreEq(obj, lines, backend)
            for i=1:numel(obj.bodyEqs)
                eq = obj.bodyEqs{i};
                if ~isa(eq, 'LustreEq')
                    % assumptions, guarantees, modes...
                    lines{end+1} = sprintf('\t%s\n', ...
                        eq.print(backend));
                    continue;
                end
                if numel(eq.lhs) > 1
                    var = eq.lhs{1};
                else
                    var = eq.lhs;
                end
                if ~isa(var, 'LustreVar') && ~isa(var, 'VarIdExpr')
                    continue;
                end
                if isa(var, 'LustreVar')
                    varDT = var.getDT();
                else
                    varDT = obj.getDT(obj.localVars, var.getId());
                end
                
                lines{end+1} = sprintf('\tvar %s : %s = %s;\n', ...
                    var.getId(), varDT, eq.rhs.print(backend));
            end
        end
    end
    
end

