
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Lustre node inputs, outputs
function [node_name,  node_inputs_cell, node_outputs_cell,...
        node_inputs_withoutDT_cell, node_outputs_withoutDT_cell ] = ...
        extractNodeHeader(parent_ir, blk, is_main_node, ...
        isEnableORAction, isEnableAndTrigger, isContractBlk, isMatlabFunction, ...
        main_sampleTime, xml_trace)
    %L = nasa_toLustre.ToLustreImport.L;% Avoiding importing functions. Use direct indexing instead for safe call
    %import(L{:})
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
        nasa_toLustre.utils.SLX2LusUtils.extract_node_InOutputs_withDT(blk, 'Inport', xml_trace);

    % add the execution condition if it is a conditionally executed
    % SS
    if isEnableORAction
        node_inputs_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
            nasa_toLustre.utils.SLX2LusUtils.isEnabledStr() , 'bool');
        % we don't include them in node_inputs_withoutDT_cell, see
        % condExecSS_To_LusAutomaton
        %node_inputs_withoutDT_cell{end + 1} = VarIdExpr(...
        %    nasa_toLustre.utils.SLX2LusUtils.isEnabledStr());
    elseif isEnableAndTrigger
        node_inputs_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
            nasa_toLustre.utils.SLX2LusUtils.isEnabledStr() , 'bool');
        % we don't include them in node_inputs_withoutDT_cell, see
        % condExecSS_To_LusAutomaton
        %node_inputs_withoutDT_cell{end + 1} = VarIdExpr(...
        %    nasa_toLustre.utils.SLX2LusUtils.isEnabledStr());
        node_inputs_cell{end + 1} = nasa_toLustre.lustreAst.LustreVar(...
            nasa_toLustre.utils.SLX2LusUtils.isTriggeredStr() , 'bool');
        % we don't include them in node_inputs_withoutDT_cell, see
        % condExecSS_To_LusAutomaton
        %node_inputs_withoutDT_cell{end + 1} = VarIdExpr(...
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
        nasa_toLustre.utils.SLX2LusUtils.extract_node_InOutputs_withDT(blk, 'Outport', xml_trace);

    if is_main_node && isempty(node_outputs_cell)
        node_outputs_cell{end+1} = nasa_toLustre.lustreAst.LustreVar(...
            nasa_toLustre.utils.SLX2LusUtils.timeStepStr(), 'real');
        node_outputs_withoutDT_cell{end+1} = nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr());
    end
end

