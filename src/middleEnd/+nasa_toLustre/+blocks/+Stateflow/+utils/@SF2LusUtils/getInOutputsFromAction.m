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
function [outputs, inputs] = getInOutputsFromAction(lus_action, isCondition, data_map, expression, isMatlab)

    
    if nargin < 5 || isempty(isMatlab)
        isMatlab = false;
    end
    outputs = {};
    inputs = {};
    
    if numel(lus_action) == 1 && isa(lus_action{1}, 'nasa_toLustre.lustreAst.ConcurrentAssignments')
        assignments = lus_action{1}.getAssignments();
    else
        assignments = lus_action;
    end
    for act_idx=1:numel(assignments)
        if ~isCondition
            if isa(assignments{act_idx}, 'nasa_toLustre.lustreAst.ConcurrentAssignments')
                [outputs_i, inputs_i] = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getInOutputsFromAction(...
                    assignments(act_idx), isCondition, data_map, expression);
                outputs = MatlabUtils.concat(outputs, outputs_i);
                inputs = MatlabUtils.concat(inputs, inputs_i);
                continue;
            elseif~isa(assignments{act_idx}, 'nasa_toLustre.lustreAst.LustreEq')
                if isMatlab
                    continue;
                end
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Action "%s" should be an assignement (e.g. outputs = f(inputs))', ...
                    expression);
                throw(ME);
            end
        end
        
        if isCondition
            inputs_names = assignments{act_idx}.GetVarIds();
            outputs_names = {};
        else
            [outputs_names, inputs_names] = assignments{act_idx}.GetVarIds();
        end
        outputs_names = unique(outputs_names);
        inputs_names = unique(inputs_names);
        
        for i=1:numel(outputs_names)
            k = outputs_names{i};
            if isKey(data_map, k)
                lusDT = nasa_toLustre.utils.MExpToLusDT.getVarDT(data_map, k);
                outputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(k, lusDT);
            else
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Variable %s can not be found for action "%s"', ...
                    k, expression);
                throw(ME);
            end
        end
        for i=1:numel(inputs_names)
            k = inputs_names{i};
            if isKey(data_map, k)
                inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(k, data_map(k).LusDatatype);
            else
                ME = MException('COCOSIM:STATEFLOW', ...
                    'Variable %s can not be found for Action "%s"', ...
                    k, expression);
                throw(ME);
            end
        end
    end
end
