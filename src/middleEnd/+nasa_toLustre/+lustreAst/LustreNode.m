classdef LustreNode < nasa_toLustre.lustreAst.LustreAst
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
                localContract, localVars, bodyEqs, isMain, isImported)
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
                obj.setMetaInfo(metaInfo);
                obj.setName(name);
                obj.setInputs(inputs);
                obj.setOutputs(outputs);
                obj.setLocalContract(localContract);
                obj.setLocalVars(localVars);
                obj.setBodyEqs(bodyEqs);
                obj.setIsMain(isMain);
            end
            if nargin < 9
                obj.isImported = false;
            else
                obj.isImported = isImported;
            end
            
            
            
        end
        
        %%
        function setMetaInfo(obj, metaInfo)
            obj.metaInfo = metaInfo;
        end
        function setName(obj, name)
            obj.name = name;
            % check the object is a valid Lustre AST.
            if ~ischar(name)
                ME = MException('COCOSIM:LUSTREAST', ...
                    'LustreNode ERROR: Expected parameter name of type char got "%s".',...
                    class(name));
                throw(ME);
            end
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
            inputsClass = unique(...
                cellfun(@(x) class(x), obj.inputs, 'UniformOutput', 0));
            if ~isempty(obj.inputs) && ~(numel(inputsClass) == 1 ...
                    && isequal(inputsClass{1}, 'nasa_toLustre.lustreAst.LustreVar'))
                ME = MException('COCOSIM:LUSTREAST', ...
                    'LustreNode ERROR: Expected inputs of type LustreVar got types "%s".',...
                    MatlabUtils.strjoin(inputsClass, ', '));
                throw(ME);
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
            outputsClass = unique(...
                cellfun(@(x) class(x), obj.outputs, 'UniformOutput', 0));
            if ~isempty(obj.outputs) && ~(numel(outputsClass) == 1 ...
                    && isequal(outputsClass{1}, 'nasa_toLustre.lustreAst.LustreVar'))
                ME = MException('COCOSIM:LUSTREAST', ...
                    'LustreNode ERROR: Expected outputs of type LustreVar got types "%s".',...
                    MatlabUtils.strjoin(outputsClass, ', '));
                throw(ME);
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
        
        function r = getBodyEqs(obj)
            r = obj.bodyEqs;
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
            if isempty(obj.localContract)
                new_localContract = obj.localContract;
            else
                new_localContract = obj.localContract.deepCopy();
            end
            new_localVars = cellfun(@(x) x.deepCopy(), obj.localVars, 'UniformOutput', 0);
            new_bodyEqs = cellfun(@(x) x.deepCopy(), obj.bodyEqs, 'UniformOutput', 0);
            new_obj = nasa_toLustre.lustreAst.LustreNode(obj.metaInfo, obj.name,...
                new_inputs, ...
                new_outputs, new_localContract, new_localVars, new_bodyEqs, ...
                obj.isMain, obj.isImported);
        end
        %% simplify expression
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.bodyEqs)
                all_obj = [all_obj; {obj.bodyEqs{i}}; obj.bodyEqs{i}.getAllLustreExpr()];
            end
        end
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), obj.bodyEqs, 'UniformOutput', true);
            nb_occ = sum(nb_occ_perEq);
        end
        %
        function new_obj = substituteVars(obj)
            new_obj = nasa_toLustre.lustreAst.LustreNode.contractNode_substituteVars(obj);
        end
        %
        function new_obj = simplify(obj)
            new_obj = obj.substituteVars();
            if ~isempty(obj.localContract)
                new_obj.setLocalContract(new_obj.localContract.simplify());
            end
            new_obj.setBodyEqs(...
                cellfun(@(x) x.simplify(), new_obj.bodyEqs, 'UniformOutput', 0));
            
        end
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            varIds = {};
            new_bodyEqs = cell(numel(obj.bodyEqs),1);
            for i=1:numel(obj.bodyEqs)
                [new_bodyEqs{i}, vId] = obj.bodyEqs{i}.changePre2Var();
                varIds = [varIds, vId];
            end
            new_obj = nasa_toLustre.lustreAst.LustreNode(obj.metaInfo, obj.name, obj.inputs, ...
                obj.outputs, obj.localContract, obj.localVars, new_bodyEqs, ...
                obj.isMain, obj.isImported);
        end
        
        function new_obj = changeArrowExp(obj, cond)
            new_bodyEqs = cellfun(@(x) x.changeArrowExp(cond), obj.bodyEqs, 'UniformOutput', 0);
            
            new_obj = nasa_toLustre.lustreAst.LustreNode(obj.metaInfo, obj.name,...
                obj.inputs, ...
                obj.outputs, obj.localContract, obj.localVars, new_bodyEqs, ...
                obj.isMain, obj.isImported);
        end
        %% This function is used for Stateflow
        function [call, oututs_Ids] = nodeCall(obj, isInner, InnerValue)
            import nasa_toLustre.frontEnd.SF_To_LustreNode
            if ~exist('isInner', 'var')
                isInner = false;
            end
            inputs_Ids = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.getId()), ...
                obj.inputs, 'UniformOutput', false);
            oututs_Ids = cellfun(@(x) nasa_toLustre.lustreAst.VarIdExpr(x.getId()), ...
                obj.outputs, 'UniformOutput', false);
            
            for i=1:numel(inputs_Ids)
                if isInner && isequal(inputs_Ids{i}.getId(), ...
                        SF2LusUtils.isInnerStr())
                    inputs_Ids{i} = InnerValue;
                elseif isequal(inputs_Ids{i}.getId(), ...
                        SF2LusUtils.virtualVarStr())
                    inputs_Ids{i} = nasa_toLustre.lustreAst.BooleanExpr(true);
                end
            end
            
            call = nasa_toLustre.lustreAst.NodeCallExpr(obj.name, inputs_Ids);
        end
        function [new_obj, varIds] = pseudoCode2Lustre(obj)
            import nasa_toLustre.lustreAst.*
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
                obj.isMain, obj.isImported);
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
                nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.inputs, backend), ...
                nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.outputs, backend));
            if ~isempty(obj.localContract)
                lines{end + 1} = obj.localContract.print(backend);
            end
            
            if obj.isImported
                code = MatlabUtils.strjoin(lines, '');
                return;
            end
            
            if ~isempty(obj.localVars)
                lines{end + 1} = sprintf('var %s\n', ...
                    nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.localVars, backend));
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
            code = obj.print_lustrec(LusBackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(LusBackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(LusBackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(LusBackendType.PRELUDE);
        end
    end
    methods(Static)
       function new_obj = contractNode_substituteVars(obj)
           import nasa_toLustre.lustreAst.*
            new_obj = obj.deepCopy();
            new_localVars = new_obj.localVars;
            outputs = new_obj.getOutputs();
            % include ConcurrentAssignments as normal Eqts
            new_bodyEqs = {};
            for i=1:numel(new_obj.bodyEqs)
                if isa(new_obj.bodyEqs{i}, 'ConcurrentAssignments')
                    new_bodyEqs = MatlabUtils.concat(new_bodyEqs, ...
                        new_obj.bodyEqs{i}.getAssignments());
                else
                    new_bodyEqs{end+1} = new_obj.bodyEqs{i};
                end
            end
            %ignore simplification if there is automaton
            all_obj = obj.getAllLustreExpr();
            all_objClass = cellfun(@(x) class(x), all_obj, 'UniformOutput', false);
            if ismember('nasa_toLustre.lustreAst.LustreAutomaton', all_objClass)
                return;
            end
            %get EveryExpr Conditions
            EveryExprObjects = all_obj(strcmp(all_objClass, 'nasa_toLustre.lustreAst.EveryExpr'));
            EveryConds = cellfun(@(x) x.getCond(), EveryExprObjects, 'UniformOutput', false);
            
            
            % go over Assignments
            for i=1:numel(new_bodyEqs)
                % e.g. y = f(x); 
                if isa(new_bodyEqs{i}, 'LustreEq')...
                        && isa(new_bodyEqs{i}.getLhs(), 'VarIdExpr')...
                        && VarIdExpr.ismemberVar(new_bodyEqs{i}.getLhs(), new_localVars)
                    var = new_bodyEqs{i}.getLhs();
                    rhs = new_bodyEqs{i}.getRhs();
                    new_var = ParenthesesExpr(rhs.deepCopy());
                    
                    % if rhs class is IteExpr, skip it. To hep debugging.
                    if isa(rhs, 'IteExpr')
                        continue;
                    end
                    % if used on its definition, skip it
                    %e.g. x = 0 -> pre x + 1;
                    if rhs.nbOccuranceVar(var) >= 1
                        continue;
                    end
                    nb_occ_perEq = cellfun(@(x) x.nbOccuranceVar(var), new_bodyEqs, 'UniformOutput', true);
                    % skip var if it is never used or used more than once. 
                    % For code readability and CEX debugging.
                    nb_occ = sum(nb_occ_perEq);
                    if nb_occ > 1
                        continue;
                    end
                    
                    % check the variable is not used in EveryExpr condition.
                    nb_occ_perEveryCond = cellfun(@(x) x.nbOccuranceVar(var), EveryConds, 'UniformOutput', true);
                    if ~isempty(nb_occ_perEveryCond) && sum(nb_occ_perEveryCond) >= 1
                        continue;
                    end
                    
                    
                    %delete the current Eqts
                    new_bodyEqs{i} = DummyExpr();
                    %remove it from variables
                    new_localVars = LustreVar.removeVar(new_localVars, var);
                    % change var by new_var
                    new_bodyEqs = cellfun(@(x) x.substituteVars(var, new_var), new_bodyEqs, 'UniformOutput', false);
                end
            end
            % remove dummyExpr
            eqsClass = cellfun(@(x) class(x), new_bodyEqs, 'UniformOutput', false);
            new_bodyEqs = new_bodyEqs(~strcmp(eqsClass, 'nasa_toLustre.lustreAst.DummyExpr'));
            new_obj.setBodyEqs(new_bodyEqs);
            new_obj.setLocalVars(new_localVars);
        end 
    end
end

