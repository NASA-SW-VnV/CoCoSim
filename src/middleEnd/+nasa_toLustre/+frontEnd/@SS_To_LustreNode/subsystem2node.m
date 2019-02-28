function [ main_node, isContractBlk, external_nodes, external_libraries ] = ...
        subsystem2node(parent_ir,  ss_ir,  main_sampleTime, ...
        is_main_node, lus_backend, coco_backend, xml_trace)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
    %L = nasa_toLustre.ToLustreImport.L;% Avoiding importing functions. Use direct indexing instead for safe call
    %import(L{:})
    %BLOCK_TO_LUSTRE create a lustre node for every Simulink subsystem within
    %subsys_struc.
    %INPUTS:
    %   subsys_struct: The internal representation of the subsystem.
    %   main_clock   : The model sample time.


    display_msg(['Compiling ', ss_ir.Path], MsgType.INFO, 'subsystem2node', '');
    % Initializing outputs
    external_nodes = {};
    main_node = {};
    external_libraries = {};
    isContractBlk =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(ss_ir);
    if ~exist('is_main_node', 'var')
        is_main_node = 0;
    end

    %% handling Stateflow
    try
        TOLUSTRE_SF_COMPILER = evalin('base', 'TOLUSTRE_SF_COMPILER');
    catch
        TOLUSTRE_SF_COMPILER =2;
    end
    if TOLUSTRE_SF_COMPILER == 1
        %Old Compiler. The new compiler is handling SF Chart in SF_To_LustreNode
        if isfield(ss_ir, 'SFBlockType') && isequal(ss_ir.SFBlockType, 'Chart')
            [main_node, external_nodes, external_libraries] = ...
                nasa_toLustre.frontEnd.SS_To_LustreNode.stateflowCode(ss_ir, xml_trace);
            return;
        end
    end
    %%

    if isContractBlk && ~LusBackendType.isKIND2(lus_backend)
        %generate contracts only for KIND2 lus_backend
        return;
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

    [body, variables, external_nodes, external_libraries] = ...
        nasa_toLustre.frontEnd.SS_To_LustreNode.write_body(ss_ir, main_sampleTime, ...
        lus_backend, coco_backend, xml_trace);
    if is_main_node
        if ~ismember(nasa_toLustre.utils.SLX2LusUtils.timeStepStr(), ...
                cellfun(@(x) {x.getId()}, node_outputs_withoutDT_cell, 'UniformOutput', 1))
            variables{end+1} = nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.utils.SLX2LusUtils.timeStepStr(), 'real');
        end
        variables{end+1} = nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.utils.SLX2LusUtils.nbStepStr(), 'int');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr()), ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            nasa_toLustre.lustreAst.RealExpr('0.0'), ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr())), ...
            nasa_toLustre.lustreAst.RealExpr(main_sampleTime(1)))));
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr()), ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            nasa_toLustre.lustreAst.IntExpr('0'), ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr())), ...
            nasa_toLustre.lustreAst.IntExpr('1'))));
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
                    variables{end+1} = nasa_toLustre.lustreAst.LustreVar(...
                        clk_name, 'bool clock');
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
        contract = nasa_toLustre.lustreAst.LustreContract('', '', {}, {}, {}, ...
            contractImports, true);
    end
    % If the Subsystem is VerificationSubsystem, then add virtual
    % output
    if isempty(node_outputs) ...
            && isfield(ss_ir, 'MaskType') ...
            && isequal(ss_ir.MaskType, 'VerificationSubsystem')
        node_outputs{end+1} = nasa_toLustre.lustreAst.LustreVar('VerificationSubsystem_virtual', 'bool');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('VerificationSubsystem_virtual'),  nasa_toLustre.lustreAst.BooleanExpr(true));
    end
    % If the Subsystem has VerificationSubsystem, then add virtual
    % variable
    [hasVerificationSubsystem, hasNoOutputs, vsBlk] = nasa_toLustre.blocks.SubSystem_To_Lustre.hasVerificationSubsystem(ss_ir);
    if hasVerificationSubsystem && hasNoOutputs
        vs_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(vsBlk);
        variables{end+1} = nasa_toLustre.lustreAst.LustreVar(strcat(vs_name, '_virtual'), 'bool');
    end
    % Adding lustre comments tracking the original path
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Original block name: %s', ss_ir.Origin_path), true);
    %main_node = sprintf('%s\n%s\n%s\n%s\nlet\n\t%s\ntel\n',...
    %    comment, node_header, contract, variables_str, body);
    if isContractBlk
        main_node = nasa_toLustre.lustreAst.LustreContract(...
            comment, ...
            node_name,...
            node_inputs, ...
            node_outputs, ...
            variables, ...
            body, ...
            false);
    else
        main_node = nasa_toLustre.lustreAst.LustreNode(...
            comment, ...
            node_name,...
            node_inputs, ...
            node_outputs, ...
            contract, ...
            variables, ...
            body, ...
            is_main_node);
        if isForIteraorSS
            [main_node, iterator_node] = nasa_toLustre.frontEnd.SS_To_LustreNode.forIteratorNode(main_node, variables,...
                node_inputs, node_outputs, contract, ss_ir);
            external_nodes{end+1} = iterator_node;
        end
        if  isConditionalSS
            automaton_node = nasa_toLustre.frontEnd.condExecSS_To_LusAutomaton(parent_ir, ss_ir, ...
                hasEnablePort, hasActionPort, hasTriggerPort, isContractBlk, ...
                main_sampleTime, xml_trace);
            external_nodes{end+1} = automaton_node;
        end
    end


end

