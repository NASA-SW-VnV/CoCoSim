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
function [ main_node, isContractBlk, external_nodes, external_libraries, abstractedBlocks ] = ...
        subsystem2node(parent_ir,  ss_ir,  main_sampleTime, ...
        is_main_node, lus_backend, coco_backend, xml_trace)

    %BLOCK_TO_LUSTRE create a lustre node for every Simulink subsystem within
    %subsys_struc.
    %INPUTS:
    %   subsys_struct: The internal representation of the subsystem.
    %   main_clock   : The model sample time.
    global TOLUSTRE_TIME_STEP_ASTEQ TOLUSTRE_NB_STEP_ASTEQ;
    display_msg(['Compiling ', ss_ir.Path], MsgType.INFO, 'subsystem2node', '');
    % Initializing outputs
    external_nodes = {};
    main_node = {};
    external_libraries = {};
    abstractedBlocks = {};
    isContractBlk =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(ss_ir);
    if ~exist('is_main_node', 'var')
        is_main_node = 0;
    end

    %% handling Stateflow using Old Compiler. The new compiler is handling SF Chart in SF_To_LustreNode
    try
        TOLUSTRE_SF_COMPILER = evalin('base', 'TOLUSTRE_SF_COMPILER');
    catch
        TOLUSTRE_SF_COMPILER =2;
    end
    if TOLUSTRE_SF_COMPILER == 1
        %Old Compiler. The new compiler is handling SF Chart in SF_To_LustreNode
        if isfield(ss_ir, 'SFBlockType') && strcmp(ss_ir.SFBlockType, 'Chart')
            [main_node, external_nodes, external_libraries] = ...
                nasa_toLustre.frontEnd.SS_To_LustreNode.stateflowCode(ss_ir, xml_trace);
            return;
        end
    end
    %%

    if isContractBlk ...
            && (~coco_nasa_utils.LusBackendType.isKIND2(lus_backend) )
        %generate contracts only for KIND2 lus_backend
        % For other backends, a contract will be considered as a node
        % containing sub properties.
        isContractBlk = false;
    end


    %% creating node header

    % The case of Enable/Trigger/Action is handled in the end of this function
    % by creating an additional automaton node.
    isEnableORAction = 0;
    isEnableAndTrigger = 0;
    isMatlabFunction = false;
    [node_name, node_inputs, node_outputs,...
        node_inputs_withoutDT_cell, node_outputs_withoutDT_cell] = ...
       nasa_toLustre.utils.SLX2LusUtils.extractNodeHeader(parent_ir, ss_ir, is_main_node,...
        isEnableORAction, isEnableAndTrigger, isContractBlk, isMatlabFunction, ...
        main_sampleTime, xml_trace);



    %% Body code
    % check if abstracted
    if ~is_main_node && ~isContractBlk && isfield(parent_ir, 'MaskType')...
            && strcmp(parent_ir.MaskType, 'CoCoAbstractedSubsystem') ...
            && ~(isfield(ss_ir, 'MaskType') && strcmp(ss_ir.MaskType, 'VerificationSubsystem')) ...
            && isfield(parent_ir, 'useAbstraction') ...
            && strcmp(parent_ir.useAbstraction, 'on')
        % Abstract the node
        body = {};
        variables = {};
        isImported = true;
    else
        [body, variables, external_nodes, external_libraries, abstractedBlocks] = ...
            nasa_toLustre.frontEnd.SS_To_LustreNode.write_body(ss_ir, main_sampleTime, ...
            lus_backend, coco_backend, xml_trace);
        isImported = false;
    end
    if is_main_node
        if ~ismember(nasa_toLustre.utils.SLX2LusUtils.timeStepStr(), ...
                cellfun(@(x) {x.getId()}, node_outputs_withoutDT_cell, 'UniformOutput', 1))
            variables{end+1} = nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.utils.SLX2LusUtils.timeStepStr(), 'real');
        end
        variables{end+1} = nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.utils.SLX2LusUtils.nbStepStr(), 'int');
        body{end+1} = TOLUSTRE_TIME_STEP_ASTEQ;
        body{end+1} = TOLUSTRE_NB_STEP_ASTEQ;
        %body = [sprintf('%s = 0.0 -> pre %s + %.15f;\n\t', ...
        %  nasa_toLustre.utils.SLX2LusUtils.timeStepStr(),nasa_toLustre.utils.SLX2LusUtils.timeStepStr(), main_sampleTime(1)), body];
        %define all clocks if needed
        clocks = ss_ir.AllCompiledSampleTimes;
        if numel(clocks) > 1
            c = {};
            for i=1:numel(clocks)
                T = clocks{i};
                if T(1) < 0 || isinf(T(1))
                    continue;
                end
                st_n = T(1)/main_sampleTime(1);
                ph_n = T(2)/main_sampleTime(1);
                if ~nasa_toLustre.utils.SLX2LusUtils.isIgnoredSampleTime(st_n, ph_n)
                    clk_name =nasa_toLustre.utils.SLX2LusUtils.clockName(st_n, ph_n);
                    clk_args{1} =  nasa_toLustre.lustreAst.VarIdExpr(sprintf('%.0f',st_n));
                    clk_args{2} =  nasa_toLustre.lustreAst.VarIdExpr(sprintf('%.0f',ph_n));
                    body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
                        nasa_toLustre.lustreAst.VarIdExpr(clk_name), ...
                        nasa_toLustre.lustreAst.NodeCallExpr('_make_clock', ...
                        clk_args));
                    %body = [sprintf('%s = _make_clock(%.0f, %.0f);\n\t', ...
                    %    clk_name, st_n, ph_n), body];
                    c{end+1} = clk_name;
                    % add clocks in the begining of the variables
                    variables = coco_nasa_utils.MatlabUtils.concat({nasa_toLustre.lustreAst.LustreVar(...
                        clk_name, 'bool clock')}, variables);
                end
            end
            if ~isempty(c)
                external_libraries{end+1} = '_make_clock';
            end
        end
    end
    %% Contract
    hasEnablePort = nasa_toLustre.blocks.SubSystem_To_Lustre.hasEnablePort(ss_ir);
    hasActionPort = nasa_toLustre.blocks.SubSystem_To_Lustre.hasActionPort(ss_ir);
    hasTriggerPort = nasa_toLustre.blocks.SubSystem_To_Lustre.hasTriggerPort(ss_ir);
    isConditionalSS = hasEnablePort || hasActionPort || hasTriggerPort;
    isForIteraorSS = nasa_toLustre.blocks.SubSystem_To_Lustre.hasForIterator(ss_ir);
    % creating contract
    contract = {};
    % the contract of conditional SS is done in the automaton node
    if isfield(ss_ir, 'ContractNodeNames')
        contractImports = nasa_toLustre.frontEnd.SS_To_LustreNode.getImportedContracts(...
                parent_ir, ss_ir, main_sampleTime, node_inputs_withoutDT_cell, node_outputs_withoutDT_cell);
        if ~coco_nasa_utils.CoCoBackendType.isDED(coco_backend) && (coco_nasa_utils.LusBackendType.isKIND2(lus_backend) ...
                || coco_nasa_utils.LusBackendType.isLUSTREC(lus_backend))
            %import contract
            contract = nasa_toLustre.lustreAst.LustreContract('', '', {}, {}, {}, ...
                contractImports, true);
        end
    end
    % If the Subsystem is VerificationSubsystem, then add virtual
    % output
    if isempty(node_outputs) ...
            && isfield(ss_ir, 'MaskType') ...
            && strcmp(ss_ir.MaskType, 'VerificationSubsystem')
        node_outputs{end+1} = nasa_toLustre.lustreAst.LustreVar('VerificationSubsystem_virtual', 'bool');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('VerificationSubsystem_virtual'),  nasa_toLustre.lustreAst.BoolExpr(true));
    end
    
    
    % If the Subsystem has VerificationSubsystem, then add virtual
    % variable
    %% Done in SubSystem_To_Lustre
    %     [hasVerificationSubsystem, hasNoOutputs, vsBlk] = nasa_toLustre.blocks.SubSystem_To_Lustre.hasVerificationSubsystem(ss_ir);
    %     if hasVerificationSubsystem && hasNoOutputs
    %         vs_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(vsBlk);
    %         variables{end+1} = nasa_toLustre.lustreAst.LustreVar(strcat(vs_name, '_virtual'), 'bool');
    %     end
    
    
    %% Adding lustre comments tracking the original path
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Original block name: %s', ss_ir.Origin_path), true);
    %main_node = sprintf('%s\n%s\n%s\n%s\nlet\n\t%s\ntel\n',...
    %    comment, node_header, contract, variables_str, body);
    if isContractBlk && coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
        % add time_step and nb_step assumptions
        if ~isempty(TOLUSTRE_NB_STEP_ASTEQ)
            body{end+1} = nasa_toLustre.lustreAst.ContractAssumeExpr('NB_STEP', ...
                nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
                TOLUSTRE_NB_STEP_ASTEQ.getLhs(), ...
                TOLUSTRE_NB_STEP_ASTEQ.getRhs()));
            body{end+1} = nasa_toLustre.lustreAst.ContractAssumeExpr('TIME_STEP', ...
                nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
                TOLUSTRE_TIME_STEP_ASTEQ.getLhs(), ...
                TOLUSTRE_TIME_STEP_ASTEQ.getRhs()));
        end
        main_node = nasa_toLustre.lustreAst.LustreContract(...
            comment, ...
            node_name,...
            node_inputs, ...
            node_outputs, ...
            variables, ...
            body, ...
            false);
    else
        % Not a contract block
        isContractBlk = 0;
        main_node = nasa_toLustre.lustreAst.LustreNode(...
            comment, ...
            node_name,...
            node_inputs, ...
            node_outputs, ...
            contract, ...
            variables, ...
            body, ...
            is_main_node, ...
            isImported);
        if isForIteraorSS
            [main_node, iterator_node] = nasa_toLustre.frontEnd.SS_To_LustreNode.forIteratorNode(main_node, variables,...
                node_inputs, node_outputs, contract, ss_ir);
            external_nodes{end+1} = iterator_node;
        end
        if  isConditionalSS
            % condExecSS_To_LusAutomaton
            external_nodes_i = nasa_toLustre.frontEnd.condExecSS_To_LusMerge(parent_ir, ss_ir, lus_backend,...
                hasEnablePort, hasActionPort, hasTriggerPort, isContractBlk, ...
                main_sampleTime, xml_trace);
            external_nodes = coco_nasa_utils.MatlabUtils.concat(external_nodes, external_nodes_i);
        end
    end


end

