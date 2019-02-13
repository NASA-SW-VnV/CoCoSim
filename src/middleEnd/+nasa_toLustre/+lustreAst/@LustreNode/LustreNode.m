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
        setMetaInfo(obj, metaInfo)

        setName(obj, name)

        name = getName(obj)

        inputs = getInputs(obj)

        setInputs(obj, inputs)

        outputs = getOutputs(obj)

        setOutputs(obj, outputs)
       
        setLocalContract(obj, localContract)

        setLocalVars(obj, localVars)

        addVar(obj, v)

        setBodyEqs(obj, bodyEqs)

        addBodyEqs(obj, eq)

        r = getBodyEqs(obj)

        setIsMain(obj, isMain)

        setIsImported(obj, isImported)

        %%
        new_obj = deepCopy(obj)

        %% simplify expression
        all_obj = getAllLustreExpr(obj)

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

        [new_obj, varIds] = pseudoCode2Lustre(obj)

        %% This is used by KIND2 LustreProgram.print()
        nodesCalled = getNodesCalled(obj)
         
        %%
        code = print(obj, backend)

        code = print_lustrec(obj, backend)
       
        code = print_kind2(obj)

        code = print_zustre(obj)

        code = print_jkind(obj)

        code = print_prelude(obj)

    end
    methods(Static)
       new_obj = contractNode_substituteVars(obj)

    end
end

