%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef LustreContract < nasa_toLustre.lustreAst.LustreAst
    %LustreContract

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
                if strcmp(localVars{i}.getId(), varID)
                    dt = localVars{i}.type;
                    break;
                end
            end
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
        
        %% simplify expression
        new_obj = simplify(obj)
        
        %% nbOccuranceVar
        nb_occ = nbOccuranceVar(obj, var)
        
         %% substituteVars 
        new_obj = substituteVars(obj)
        
        %% This functions are used for ForIterator block
        [new_obj, varIds] = changePre2Var(obj)
        new_obj = changeArrowExp(obj, ~)
        
        %% This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
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
        code = print(obj, varargin)
        
        code = print_lustrec(obj)
        
        code = print_kind2(obj, backend)
        code = print_zustre(obj)
        code = print_jkind(obj)
        code = print_prelude(obj)
        
        %% utils
        lines = getLustreEq(obj, lines, backend)
    end
    
end

