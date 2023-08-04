
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
%% Lustre node inputs, outputs
function [node_name,  node_inputs_cell, node_outputs_cell,...
        node_inputs_withoutDT_cell, node_outputs_withoutDT_cell ] = ...
        extractNodeHeader(parent_ir, blk, is_main_node, ...
        isEnableORAction, isEnableAndTrigger, isContractBlk, isMatlabFunction, ...
        main_sampleTime, xml_trace)
    %
    %
    % this function is used to get the Lustre node inputs and
    % outputs.


    % creating node header
    node_name = nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);


    % contract handling
    if isContractBlk
        [ node_inputs_cell, node_outputs_cell,...
            node_inputs_withoutDT_cell, node_outputs_withoutDT_cell ] = ...
            nasa_toLustre.utils.SLX2LusUtils.extractContractHeader(parent_ir, blk, main_sampleTime, xml_trace);
        return;
    end
     % create traceability
    xml_trace.create_Node_Element(blk.Origin_path, node_name,...
        nasa_toLustre.utils.SLX2LusUtils.isContractBlk(blk)); % not using isContractBlk 
    %variable because it may be 0 if the functions is called from nasa_toLustre.utils.SLX2LusUtils.extractContractHeader


    %creating inputs
    xml_trace.create_Inputs_Element();
    [node_inputs_cell, node_inputs_withoutDT_cell] = ...
        nasa_toLustre.utils.SLX2LusUtils.extract_node_InOutputs_withDT(blk, 'Inport', xml_trace, main_sampleTime);
    % add the execution condition if it is a conditionally executed
    % SS
    if isEnableORAction
        node_inputs_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
            nasa_toLustre.utils.SLX2LusUtils.isEnabledStr() , 'bool');
        % we don't include them in node_inputs_withoutDT_cell, see
        % condExecSS_To_LusAutomaton
        %node_inputs_withoutDT_cell{end + 1} = nasa_toLustre.lustreAst.VarIdExpr(...
        %    nasa_toLustre.utils.SLX2LusUtils.isEnabledStr());
    elseif isEnableAndTrigger
        node_inputs_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
            nasa_toLustre.utils.SLX2LusUtils.isEnabledStr() , 'bool');
        % we don't include them in node_inputs_withoutDT_cell, see
        % condExecSS_To_LusAutomaton
        %node_inputs_withoutDT_cell{end + 1} = nasa_toLustre.lustreAst.VarIdExpr(...
        %    nasa_toLustre.utils.SLX2LusUtils.isEnabledStr());
        node_inputs_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
            nasa_toLustre.utils.SLX2LusUtils.isTriggeredStr() , 'bool');
        % we don't include them in node_inputs_withoutDT_cell, see
        % condExecSS_To_LusAutomaton
        %node_inputs_withoutDT_cell{end + 1} = nasa_toLustre.lustreAst.VarIdExpr(...
        %    nasa_toLustre.utils.SLX2LusUtils.isTriggeredStr());
    end
    %add simulation time input and clocks
    if ~is_main_node && ~isMatlabFunction
        [node_inputs_cell, node_inputs_withoutDT_cell] = ...
        nasa_toLustre.utils.SLX2LusUtils.getTimeClocksInputs(blk, main_sampleTime, node_inputs_cell, node_inputs_withoutDT_cell);
    end
    % if the node has no inputs, add virtual input for Lustrec.
    if isempty(node_inputs_cell)
        node_inputs_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar('_virtual', 'bool');
        node_inputs_withoutDT_cell{end+1} = nasa_toLustre.lustreAst.VarIdExpr('_virtual');
    end

    % creating outputs
    xml_trace.create_Outputs_Element();
    [node_outputs_cell, node_outputs_withoutDT_cell] =...
        nasa_toLustre.utils.SLX2LusUtils.extract_node_InOutputs_withDT(blk, 'Outport', xml_trace, main_sampleTime);

    if is_main_node && isempty(node_outputs_cell)
        node_outputs_cell{end+1} = nasa_toLustre.lustreAst.LustreVar(...
            nasa_toLustre.utils.SLX2LusUtils.timeStepStr(), 'real');
        node_outputs_withoutDT_cell{end+1} = nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr());
    end
end

