classdef LustreNode < nasa_toLustre.lustreAst.LustreAst
    %LustreNode
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
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
                    && strcmp(inputsClass{1}, 'nasa_toLustre.lustreAst.LustreVar'))
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
                    && strcmp(outputsClass{1}, 'nasa_toLustre.lustreAst.LustreVar'))
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

        addVar(obj, v)

        function setBodyEqs(obj, bodyEqs)
            if ~iscell(bodyEqs) && numel(bodyEqs) == 1
                obj.bodyEqs{1} = bodyEqs;
            else
                obj.bodyEqs = bodyEqs;
            end
        end

        addBodyEqs(obj, eq)

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
        new_obj = deepCopy(obj)

        %% simplify expression
        function all_obj = getAllLustreExpr(obj)
            all_obj = {};
            for i=1:numel(obj.bodyEqs)
                all_obj = [all_obj; {obj.bodyEqs{i}}; obj.bodyEqs{i}.getAllLustreExpr()];
            end
        end

        nb_occ = nbOccuranceVar(obj, var)

        %
        new_obj = substituteVars(obj)

        %
        new_obj = simplify(obj)

        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)

        new_obj = changeArrowExp(obj, cond)

        %% This is used for Stateflow
        [call, oututs_Ids] = nodeCall(obj, isInner, InnerValue)

        [new_obj, varIds] = pseudoCode2Lustre(obj, data_map)

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
        code = print(obj, backend, inPreludeFile)

        code = print_lustrec(obj, backend)
       
        code = print_kind2(obj)

        code = print_zustre(obj)

        code = print_jkind(obj)

        code = print_prelude(obj)
        
        code = print_preludeImportedNode(obj);

    end
    methods(Static)
       obj = contractNode_substituteVars(obj)

    end
end

