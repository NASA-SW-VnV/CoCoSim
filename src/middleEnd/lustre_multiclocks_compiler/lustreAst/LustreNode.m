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
                obj.inputs = inputs;
                obj.outputs = outputs;
                obj.localContract = localContract;
                obj.localVars = localVars;
                obj.bodyEqs = bodyEqs;
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
            obj.inputs = inputs;
        end
        function outputs = getOutputs(obj)
            outputs = obj.outputs;
        end
        function setOutputs(obj, outputs)
            obj.outputs = outputs;
        end

        function setLocalContract(obj, localContract)
            obj.localContract = localContract;
        end
        function setLocalVars(obj, localVars)
            obj.localVars = localVars;
        end
        function setBodyEqs(obj, bodyEqs)
            obj.bodyEqs = bodyEqs;
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
            if iscell(obj.localContract)
                new_localContract = cellfun(@(x) x.deepCopy(), obj.localContract, 'UniformOutput', 0);
            else
                new_localContract = obj.localContract.deepCopy();
            end
            if iscell(obj.localVars)
                new_localVars = cellfun(@(x) x.deepCopy(), obj.localVars, 'UniformOutput', 0);
            else
                new_localVars = obj.localVars.deepCopy();
            end
            if iscell(obj.bodyEqs)
                new_bodyEqs = cellfun(@(x) x.deepCopy(), obj.bodyEqs, 'UniformOutput', 0);
            else
                new_bodyEqs = obj.bodyEqs.deepCopy();
            end
            
            new_obj = LustreNode(obj.metaInfo, obj.name,...
                new_inputs, ...
                new_outputs, new_localContract, new_localVars, new_bodyEqs, ...
                obj.isMain);
        end
        
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            if iscell(obj.bodyEqs)
                new_bodyEqs = {};
                for i=1:numel(obj.bodyEqs)
                    [new_bodyEqs{i}, vId] = obj.bodyEqs{i}.changePre2Var();
                    varIds = [varIds, vId];
                end
            else
                [new_bodyEqs, varIds] = obj.bodyEqs.changePre2Var();
            end
            new_obj = LustreNode(obj.metaInfo, obj.name, obj.inputs, ...
                obj.outputs, obj.localContract, obj.localVars, new_bodyEqs, ...
                obj.isMain);
        end
        
        function new_obj = changeArrowExp(obj, cond)
            if iscell(obj.bodyEqs)
                new_bodyEqs = cellfun(@(x) x.changeArrowExp(cond), obj.bodyEqs, 'UniformOutput', 0);
            else
                new_bodyEqs = obj.bodyEqs.changeArrowExp(cond);
            end
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
            if iscell(obj.bodyEqs)
                for i=1:numel(obj.bodyEqs)
                    eq = obj.bodyEqs{i};
                    if isempty(eq)
                        continue;
                    end
                    lines{end+1} = sprintf('\t%s\n', ...
                        eq.print(backend));

                end
            elseif ~isempty(obj.bodyEqs)
                lines{end+1} = sprintf('\t%s\n', ...
                    obj.bodyEqs.print(backend));
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

