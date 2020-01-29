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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [new_obj, varIds] = pseudoCode2Lustre(obj, data_map)
        varIds = {};
    outputs_map = containers.Map('KeyType', 'char', 'ValueType', 'int32');

    %initialize outputs_map
    for i=1:numel(obj.outputs)
        outputs_map(obj.outputs{i}.getId()) = 0;
    end
    for i=1:numel(obj.localVars)
        outputs_map(obj.localVars{i}.getId()) = 0;
    end
    % go over body equations to change each occurance of outputs to new var
    new_bodyEqs = cell(numel(obj.bodyEqs),1);
    isLeft = false;
    I = [];
    for i=1:numel(obj.bodyEqs)
        if ~isa(obj.bodyEqs{i}, 'nasa_toLustre.lustreAst.LustreEq') ...
                && ~isa(obj.bodyEqs{i}, 'nasa_toLustre.lustreAst.ConcurrentAssignments')
            %Keep Assertions, localProperties till the end to use
            %the last occurance.
            I = [I i];
            continue;
        end
        [new_bodyEqs{i}, outputs_map] = ...
            obj.bodyEqs{i}.pseudoCode2Lustre(outputs_map, isLeft, obj, data_map);
    end

    %Go over Assertions, localProperties, ...
    for i=I
        [new_bodyEqs{i}, outputs_map] = ...
            obj.bodyEqs{i}.pseudoCode2Lustre(outputs_map, isLeft, obj, data_map);
    end
    if ~isempty(obj.localContract)
        new_localContract = obj.localContract.pseudoCode2Lustre(outputs_map, isLeft, obj, data_map);
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
                nasa_toLustre.lustreAst.LustreVar(strcat(out_name, '__', num2str(j)),...
                out_DT));
        end
        if last_Idx > 0
            obj.outputs{i} = ...
                nasa_toLustre.lustreAst.LustreVar(strcat(out_name, '__', num2str(last_Idx)),...
                out_DT);
        end
    end
    tobeRemoved = {};
    for i=1:numel(obj.localVars)
        out_name = obj.localVars{i}.getId();
        out_DT = obj.localVars{i}.getDT();
        if ~isKey(outputs_map, out_name)
            continue;
        end
        last_Idx = outputs_map(out_name);
        if last_Idx >= 1
            tobeRemoved{end+1} = obj.localVars{i};
        end
        for j=1:last_Idx
            obj.addVar(...
                nasa_toLustre.lustreAst.LustreVar(strcat(out_name, '__', num2str(j)),...
                out_DT));
        end
        
    end
    for i=1:length(tobeRemoved)
        obj.localVars =...
               nasa_toLustre.lustreAst.LustreVar.removeVar(obj.localVars, tobeRemoved{i});
    end
    % construct the node
    new_obj = nasa_toLustre.lustreAst.LustreNode(obj.metaInfo, obj.name, obj.inputs, ...
        obj.outputs, new_localContract, obj.localVars, new_bodyEqs, ...
        obj.isMain, obj.isImported);
end
