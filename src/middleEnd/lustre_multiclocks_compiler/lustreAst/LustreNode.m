classdef LustreNode < LustreAst
    %LustreNode
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        metaInfo;%String
        name;%String
        inputs;
        outputs;
        localContract;
        localVars;
        bodyEqs;
        isMain;
        isImported;
    end
    
    methods
        function obj = LustreNode(metaInfo, name, inputs, outputs, ...
                localContract, localVars, bodyEqs, isMain)
            if nargin==0
                obj.metaInfo = '';
                obj.name = '';
                obj.inputs = {};
                obj.outputs = {};
                obj.localContract = {};
                obj.localVars = {};
                obj.bodyEqs = {};
                obj.isMain = false;
            else
                obj.metaInfo = metaInfo;
                obj.name = name;
                obj.setInputs(inputs);
                obj.setOutputs(outputs);
                obj.setLocalContract(localContract);
                obj.setLocalVars(localVars);
                obj.setBodyEqs(bodyEqs);
                obj.isMain = isMain;
            end
            obj.isImported = false;
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
        
        function setLocalContract(obj, localContract)
            if iscell(localContract) && numel(localContract) == 1
                obj.localContract = localContract{1};
            elseif iscell(localContract) && numel(localContract) > 1
                display_msg(...
                    sprintf(['Node %s has more than one contract.', ...
                    ' A node can contain only one local contract. ', ...
                    'The first one will be used.'], obj.name), ...
                    MsgType.ERROR, 'LustreNode', '');
                
                obj.localContract = localContract{1};
            else
                obj.localContract = localContract;
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
            if ~iscell(bodyEqs) && numel(bodyEqs) == 1
                obj.bodyEqs{1} = bodyEqs;
            else
                obj.bodyEqs = bodyEqs;
            end
        end
        function addBodyEqs(obj, eq)
            obj.bodyEqs{end+1} = eq;
        end
        function setIsMain(obj, isMain)
            obj.isMain = isMain;
        end
        function setIsImported(obj, isImported)
            obj.isImported = isImported;
        end
        %%
        function new_obj = deepCopy(obj)
            new_inputs = cellfun(@(x) x.deepCopy(), obj.inputs, 'UniformOutput', 0);
            new_outputs = cellfun(@(x) x.deepCopy(), obj.outputs, 'UniformOutput', 0);
            new_localContract = obj.localContract.deepCopy();
            new_localVars = cellfun(@(x) x.deepCopy(), obj.localVars, 'UniformOutput', 0);
            new_bodyEqs = cellfun(@(x) x.deepCopy(), obj.bodyEqs, 'UniformOutput', 0);
            new_obj = LustreNode(obj.metaInfo, obj.name,...
                new_inputs, ...
                new_outputs, new_localContract, new_localVars, new_bodyEqs, ...
                obj.isMain);
        end
        
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            new_bodyEqs = cell(numel(obj.bodyEqs),1);
            for i=1:numel(obj.bodyEqs)
                [new_bodyEqs{i}, vId] = obj.bodyEqs{i}.changePre2Var();
                varIds = [varIds, vId];
            end
            new_obj = LustreNode(obj.metaInfo, obj.name, obj.inputs, ...
                obj.outputs, obj.localContract, obj.localVars, new_bodyEqs, ...
                obj.isMain);
        end
        
        function new_obj = changeArrowExp(obj, cond)
            new_bodyEqs = cellfun(@(x) x.changeArrowExp(cond), obj.bodyEqs, 'UniformOutput', 0);
            
            new_obj = LustreNode(obj.metaInfo, obj.name,...
                obj.inputs, ...
                obj.outputs, obj.localContract, obj.localVars, new_bodyEqs, ...
                obj.isMain);
        end
        %% This function is used for Stateflow
        function [call, oututs_Ids] = nodeCall(obj, isInner, InnerValue)
            if ~exist('isInner', 'var')
                isInner = false;
            end
            inputs_Ids = cellfun(@(x) VarIdExpr(x.getId()), ...
                obj.inputs, 'UniformOutput', false);
            oututs_Ids = cellfun(@(x) VarIdExpr(x.getId()), ...
                obj.outputs, 'UniformOutput', false);
            
            for i=1:numel(inputs_Ids)
                if isInner && isequal(inputs_Ids{i}.getId(), ...
                        StateflowState_To_Lustre.isInnerStr())
                    inputs_Ids{i} = InnerValue;
                elseif isequal(inputs_Ids{i}.getId(), ...
                        SF_To_LustreNode.virtualVarStr())
                    inputs_Ids{i} = BooleanExpr(true);
                end
            end
            
            call = NodeCallExpr(obj.name, inputs_Ids);
        end
        function [new_obj, varIds] = pseudoCode2Lustre(obj)
            varIds = {};
            outputs_map = containers.Map('KeyType', 'char', 'ValueType', 'int32');
            
            %initialize outputs_map
            for i=1:numel(obj.outputs)
                outputs_map(obj.outputs{i}.getId()) = 0;
            end
            
            % go over body equations to change each occurance of outputs to new var
            new_bodyEqs = cell(numel(obj.bodyEqs),1);
            isLeft = false;
            I = [];
            for i=1:numel(obj.bodyEqs)
                if ~isa(obj.bodyEqs{i}, 'LustreEq') ...
                        && ~isa(obj.bodyEqs{i}, 'ConcurrentAssignments')
                    %Keep Assertions, localProperties till the end to use 
                    %the last occurance.
                    I = [I i];
                    continue;
                end
                [new_bodyEqs{i}, outputs_map] = ...
                    obj.bodyEqs{i}.pseudoCode2Lustre(outputs_map, isLeft);
            end
            
            %Go over Assertions, localProperties, ...
            for i=I
                [new_bodyEqs{i}, outputs_map] = ...
                    obj.bodyEqs{i}.pseudoCode2Lustre(outputs_map, isLeft);
            end
            if ~isempty(obj.localContract)
                new_localContract = obj.localContract.pseudoCode2Lustre(outputs_map, isLeft);
            else
                new_localContract = obj.localContract;
            end
            %add the new vars and change outputs names to the last occurance
            for i=1:numel(obj.outputs)
                out_name = obj.outputs{i}.getId();
                out_DT = obj.outputs{i}.getDT();
                last_Idx = outputs_map(out_name);
                for j=1:last_Idx-1
                    obj.addVar(...
                        LustreVar(strcat(out_name, '__', num2str(j)),...
                        out_DT));
                end
                if last_Idx > 0
                    obj.outputs{i} = ...
                        LustreVar(strcat(out_name, '__', num2str(last_Idx)),...
                        out_DT);
                end
            end
            new_obj = LustreNode(obj.metaInfo, obj.name, obj.inputs, ...
                obj.outputs, new_localContract, obj.localVars, new_bodyEqs, ...
                obj.isMain);
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
            addNodes(obj.localContract);
            addNodes(obj.bodyEqs);
        end
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        function code = print_lustrec(obj, backend)
            lines = {};
            if ~isempty(obj.metaInfo)
                if ischar(obj.metaInfo)
                    lines{end + 1} = sprintf('(*\n%s\n*)\n',...
                        obj.metaInfo);
                else
                    lines{end + 1} = obj.metaInfo.print(backend);
                end
            end
            if obj.isImported
                isImported_str = 'imported';
            else
                isImported_str = '';
            end
            lines{end + 1} = sprintf('node %s %s(%s)\nreturns(%s);\n', ...
                isImported_str, ...
                obj.name, ...
                LustreAst.listVarsWithDT(obj.inputs, backend), ...
                LustreAst.listVarsWithDT(obj.outputs, backend));
            if ~isempty(obj.localContract)
                lines{end + 1} = obj.localContract.print(backend);
            end
            
            if obj.isImported
                code = MatlabUtils.strjoin(lines, '');
                return;
            end
            
            if ~isempty(obj.localVars)
                lines{end + 1} = sprintf('var %s\n', ...
                    LustreAst.listVarsWithDT(obj.localVars, backend));
            end
            lines{end+1} = sprintf('let\n');
            % local Eqs
            for i=1:numel(obj.bodyEqs)
                eq = obj.bodyEqs{i};
                if isempty(eq)
                    continue;
                end
                lines{end+1} = sprintf('\t%s\n', ...
                    eq.print(backend));
                
            end
            lines{end+1} = sprintf('tel\n');
            code = MatlabUtils.strjoin(lines, '');
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

