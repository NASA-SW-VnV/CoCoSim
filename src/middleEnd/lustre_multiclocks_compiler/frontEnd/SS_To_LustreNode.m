classdef SS_To_LustreNode
    %SS_TO_LUSTRENODE translates a Subsystem to Lustre node
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods(Static)
        function [ main_node, isContractBlk, external_nodes, external_libraries ] = ...
                subsystem2node(parent_ir,  ss_ir,  main_sampleTime, ...
                is_main_node, backend, xml_trace)
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
            isContractBlk = SLX2LusUtils.isContractBlk(ss_ir);
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
                        SS_To_LustreNode.stateflowCode(ss_ir, xml_trace);
                    return;
                end
            end
            %%
            
            if isContractBlk && ~BackendType.isKIND2(backend)
                %generate contracts only for KIND2 backend
                return;
            end
            
            
            %% creating node header
            
            % The case of Enable/Trigger/Action is handled in the end of this function
            % by creating an additional automaton node.
            isEnableORAction = 0;
            isEnableAndTrigger = 0;
            [node_name, node_inputs, node_outputs,...
                node_inputs_withoutDT_cell, node_outputs_withoutDT_cell] = ...
                SLX2LusUtils.extractNodeHeader(parent_ir, ss_ir, is_main_node,...
                isEnableORAction, isEnableAndTrigger, isContractBlk, ...
                main_sampleTime, xml_trace);
            
            
            
            %% Body code
            
            [body, variables, external_nodes, external_libraries] = ...
                SS_To_LustreNode.write_body(ss_ir, main_sampleTime, ...
                backend, xml_trace);
            if is_main_node
                if ~ismember(SLX2LusUtils.timeStepStr(), ...
                        cellfun(@(x) {x.getId()}, node_outputs_withoutDT_cell, 'UniformOutput', 1))
                    variables{end+1} = LustreVar(SLX2LusUtils.timeStepStr(), 'real');
                end
                variables{end+1} = LustreVar(SLX2LusUtils.nbStepStr(), 'int');
                body{end+1} = LustreEq(VarIdExpr(SLX2LusUtils.timeStepStr()), ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                    RealExpr('0.0'), ...
                    BinaryExpr(BinaryExpr.PLUS, ...
                    UnaryExpr(UnaryExpr.PRE, VarIdExpr(SLX2LusUtils.timeStepStr())), ...
                    RealExpr(main_sampleTime(1)))));
                body{end+1} = LustreEq(VarIdExpr(SLX2LusUtils.nbStepStr()), ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                    IntExpr('0'), ...
                    BinaryExpr(BinaryExpr.PLUS, ...
                    UnaryExpr(UnaryExpr.PRE, VarIdExpr(SLX2LusUtils.nbStepStr())), ...
                    IntExpr('1'))));
                %body = [sprintf('%s = 0.0 -> pre %s + %.15f;\n\t', ...
                %   SLX2LusUtils.timeStepStr(), SLX2LusUtils.timeStepStr(), main_sampleTime(1)), body];
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
                        if ~SLX2LusUtils.isIgnoredSampleTime(st_n, ph_n)
                            clk_name = SLX2LusUtils.clockName(st_n, ph_n);
                            clk_args{1} =  VarIdExpr(sprintf('%.0f',st_n));
                            clk_args{2} =  VarIdExpr(sprintf('%.0f',ph_n));
                            body{end+1} = LustreEq(...
                                VarIdExpr(clk_name), ...
                                NodeCallExpr('_make_clock', ...
                                clk_args));
                            %body = [sprintf('%s = _make_clock(%.0f, %.0f);\n\t', ...
                            %    clk_name, st_n, ph_n), body];
                            c{end+1} = clk_name;
                            variables{end+1} = LustreVar(...
                                clk_name, 'bool clock');
                        end
                    end
                    if ~isempty(c)
                        external_libraries{end+1} = '_make_clock';
                    end
                end
            end
            %% Contract
            hasEnablePort = SubSystem_To_Lustre.hasEnablePort(ss_ir);
            hasActionPort = SubSystem_To_Lustre.hasActionPort(ss_ir);
            hasTriggerPort = SubSystem_To_Lustre.hasTriggerPort(ss_ir);
            isConditionalSS = hasEnablePort || hasActionPort || hasTriggerPort;
            isForIteraorSS = SubSystem_To_Lustre.hasForIterator(ss_ir);
            % creating contract
            contract = {};
            % the contract of conditional SS is done in the automaton node
            if isfield(ss_ir, 'ContractNodeNames')
                contractImports = SS_To_LustreNode.getImportedContracts(...
                    parent_ir, ss_ir, main_sampleTime, node_inputs_withoutDT_cell, node_outputs_withoutDT_cell);
                contract = LustreContract('', '', {}, {}, {}, ...
                    contractImports, true);
            end
            % If the Subsystem is VerificationSubsystem, then add virtual
            % output
            if isempty(node_outputs) ...
                    && isfield(ss_ir, 'MaskType') ...
                    && isequal(ss_ir.MaskType, 'VerificationSubsystem')
                node_outputs{end+1} = LustreVar('VerificationSubsystem_virtual', 'bool');
                body{end+1} = LustreEq(VarIdExpr('VerificationSubsystem_virtual'),  BooleanExpr(true));
            end
            % If the Subsystem has VerificationSubsystem, then add virtual
            % variable
            [hasVerificationSubsystem, hasNoOutputs, vsBlk] = SubSystem_To_Lustre.hasVerificationSubsystem(ss_ir);
            if hasVerificationSubsystem && hasNoOutputs
                vs_name = SLX2LusUtils.node_name_format(vsBlk);
                variables{end+1} = LustreVar(strcat(vs_name, '_virtual'), 'bool');
            end
            % Adding lustre comments tracking the original path
            comment = LustreComment(...
                sprintf('Original block name: %s', ss_ir.Origin_path), true);
            %main_node = sprintf('%s\n%s\n%s\n%s\nlet\n\t%s\ntel\n',...
            %    comment, node_header, contract, variables_str, body);
            if isContractBlk
                main_node = LustreContract(...
                    comment, ...
                    node_name,...
                    node_inputs, ...
                    node_outputs, ...
                    variables, ...
                    body, ...
                    false);
            else
                main_node = LustreNode(...
                    comment, ...
                    node_name,...
                    node_inputs, ...
                    node_outputs, ...
                    contract, ...
                    variables, ...
                    body, ...
                    is_main_node);
                if isForIteraorSS
                    [main_node, iterator_node] = SS_To_LustreNode.forIteratorNode(main_node, variables,...
                        node_inputs, node_outputs, contract, ss_ir);
                    external_nodes{end+1} = iterator_node;
                end
                if  isConditionalSS
                    automaton_node = condExecSS_To_LusAutomaton(parent_ir, ss_ir, ...
                        hasEnablePort, hasActionPort, hasTriggerPort, isContractBlk, ...
                        main_sampleTime, xml_trace);
                    external_nodes{end+1} = automaton_node;
                end
            end
            
            
        end
        
        
        %% Go over SS Content
        function [body, variables, external_nodes, external_libraries] =...
                write_body(subsys, main_sampleTime, backend, xml_trace)
            variables = {};
            body = {};
            external_nodes = {};
            external_libraries = {};
            
            
            fields = fieldnames(subsys.Content);
            fields = ...
                fields(cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));
            if numel(fields)>=1
                xml_trace.create_Variables_Element();
            end
            for i=1:numel(fields)
                blk = subsys.Content.(fields{i});
                [b, status] = getWriteType(blk);
                if status
                    continue;
                end
                try
                    b.write_code(subsys, blk, xml_trace, main_sampleTime, backend);
                catch me
                    display_msg(sprintf('Translation to Lustre of block %s has failed.', blk.Origin_path),...
                        MsgType.ERROR, 'write_body', '');
                    display_msg(me.getReport(), MsgType.DEBUG, 'write_body', '');
                end
                code = b.getCode();
                if iscell(code)
                    body = [body, code];
                else
                    body{end+1} = code;
                end
                variables = [variables, b.getVariables()];
                external_nodes = [external_nodes, b.getExternalNodes()];
                external_libraries = [external_libraries, b.getExternalLibraries()];
            end
        end
        
        %% creat import contracts body
        function imported_contracts = getImportedContracts(...
                parent_ir, ss_ir, main_sampleTime, node_inputs_withoutDT, node_outputs_withoutDT)
            % contracts may have differents signature of the node imported
            % in. This function is trying to make the use of contract the most
            % flexible possible. For example having only specific inputs
            % and outputs of the node.
            imported_contracts = {};
            % creating the inputs srcBlk_srcPort information to map it
            % later
            inputs_src_str = {};
            for j=1:numel(ss_ir.PortConnectivity)
                x = ss_ir.PortConnectivity(j);
                if isempty(x.SrcBlock)
                    continue;
                else
                    srcBlk = get_struct(parent_ir, x.SrcBlock);
                    if isempty(srcBlk)
                        continue;
                    end
                    %get actual size after inlining.
                    [names, ~] = SLX2LusUtils.getBlockOutputsNames(...
                        parent_ir, srcBlk, x.SrcPort);
                    for i=1:numel(names)
                        inputs_src_str{end+1} = sprintf('%.5f_%d', x.SrcBlock, x.SrcPort);
                    end
                end
            end
            outputs_src_str = {};
            for i=1:numel(ss_ir.CompiledPortWidths.Outport)
                %get actual size after inlining.
                [names, ~] = SLX2LusUtils.getBlockOutputsNames(...
                    parent_ir, ss_ir, i-1);
                for j=1:numel(names)
                    outputs_src_str{end+1} = sprintf('%.5f_%d', ss_ir.Handle, i-1);
                end
            end
            for i=1:numel(ss_ir.ContractHandles)
                contract_inputs = {};
                contract_outputs = {};
                contract_handle = ss_ir.ContractHandles(i);
                contractBlk = get_struct(parent_ir, contract_handle);
                if isempty(contractBlk)
                    continue;
                end
                for j=1:numel(contractBlk.PortConnectivity)
                    srcBlkHandle = contractBlk.PortConnectivity(j).SrcBlock;
                    if isempty(srcBlkHandle)
                        % skip "valid" output
                        continue;
                    end
                    srcBlk = get_struct(parent_ir, srcBlkHandle);
                    if isempty(srcBlk)
                        continue;
                    end
                    SrcPort = contractBlk.PortConnectivity(j).SrcPort;
                    srcPortHandleStr =  sprintf('%.5f_%d', srcBlkHandle, SrcPort);
                    I = find(strcmp(srcPortHandleStr, inputs_src_str));
                    if ~isempty(I)
                        % we may have inputs from the same blk.
                        %get actual size after inlining.
                        [names, ~] = SLX2LusUtils.getBlockOutputsNames(...
                            parent_ir, srcBlk, SrcPort);
                        I = I(1:numel(names));
                        contract_inputs = [contract_inputs,...
                            node_inputs_withoutDT(I)];
                        continue;
                    end
                    I = find(strcmp(srcPortHandleStr, outputs_src_str));
                    if ~isempty(I)
                        contract_outputs = [contract_outputs,...
                            node_outputs_withoutDT(I)];
                        continue;
                    end
                    % case of Action inputs are ignored for the moment.
                end
                [~, contract_inputs] = ...
                    SLX2LusUtils.getTimeClocksInputs(ss_ir, main_sampleTime, {}, contract_inputs);
                imported_contracts{end+1} = ContractImportExpr(...
                    ss_ir.ContractNodeNames{i}, contract_inputs, contract_outputs);
            end
        end
        %% ForIterator block
        function [main_node, iterator_node] = forIteratorNode(main_node, variables,...
                node_inputs, node_outputs, contract, ss_ir)
            % this node will be called many times using many
            % instances in the same time step. We need to not have
            % arrow in the node as each instance of the node has
            % its own memory, therefor different is_init values.
            
            %changePre2Var
            [main_node, memoryIds] = main_node.changePre2Var();
            
            %getForIteratorMemoryVars
            [new_variables, additionalOutputs, ...
                additionalInputs, inputsMemory] =...
                SS_To_LustreNode.getForIteratorMemoryVars(variables, ...
                node_inputs, memoryIds);
            
            %changeArrowExp
            [~, ForBlk] = SubSystem_To_Lustre.hasForIterator(ss_ir);
            ShowIterationPort = isequal(ForBlk.ShowIterationPort, 'on');
            if ShowIterationPort
                iteration_dt = ForBlk.IterationVariableDataType;
                iteration_dt = SLX2LusUtils.get_lustre_dt(iteration_dt);
            else
                iteration_dt = 'int';
            end
            
            additionalInputs{end+1} = LustreVar(...
                SLX2LusUtils.iterationVariable(),  iteration_dt);
            IndexMode = ForBlk.IndexMode;
            if isequal(IndexMode, 'Zero-based')
                iterationValue = 0;
            else
                iterationValue = 1;
            end
            if isequal(iteration_dt, 'int')
                v = IntExpr(iterationValue);
            elseif isequal(iteration_dt, 'bool')
                v = BooleanExpr(iterationValue);
            else
                v = RealExpr(iterationValue);
            end
            main_node = main_node.changeArrowExp(...
                BinaryExpr(BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.EQ, ...
                VarIdExpr(SLX2LusUtils.timeStepStr()),...
                RealExpr('0.0')), ...
                BinaryExpr(BinaryExpr.EQ, ...
                VarIdExpr(SLX2LusUtils.iterationVariable()),...
                v)));
            
            main_node_inputs = [node_inputs, inputsMemory, additionalInputs];
            if ~isempty(additionalInputs) || ~isempty(inputsMemory)
                main_node.setInputs(main_node_inputs);
            end
            main_node_outputs = [node_outputs, additionalOutputs];
            if ~isempty(additionalOutputs)
                main_node.setOutputs(main_node_outputs);
            end
            main_node.setLocalVars(new_variables);
            main_node.setLocalContract({});
            % additional node
            node_name = strcat(main_node.getName(), '_iterator');
            
            iterator_variables = {};
            iterator_body ={};
            iterator_node = LustreNode(...
                '', ...
                node_name,...
                node_inputs, ...
                node_outputs, ...
                contract, ...
                iterator_variables, ...
                iterator_body, ...
                false);
            ResetStates = ForBlk.ResetStates;
            isHeld = isequal(ResetStates, 'held');
            IterationSource = ForBlk.IterationSource;
            if isequal(IterationSource, 'external')
                return;
            end
            ExternalIncrement = ForBlk.ExternalIncrement;
            if isequal(ExternalIncrement, 'on')
                return;
            end
            
            [IterationLimit, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(ss_ir, ForBlk, ForBlk.IterationLimit);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    ForBlk.IterationLimit, ForBlk.Origin_path), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            if IterationLimit == 0
                % the subsystem does not execute.
                iterator_body = cell(1, numel(node_outputs));
                for i=1:numel(node_outputs)
                    var_name = node_outputs{i}.getId();
                    var_dt = node_outputs{i}.getDT();
                    [~, zero] = SLX2LusUtils.get_lustre_dt(var_dt);
                    iterator_body{i} = LustreEq(VarIdExpr(var_name), zero);
                end
                iterator_node.setBodyEqs(iterator_body);
                return;
            end
            
            % define pre memory for inputs
            additionalInputs_with_memory = [inputsMemory, additionalInputs];
            n = numel(additionalInputs_with_memory) - 1;
            for i=1:n
                var_name = additionalInputs_with_memory{i}.getId();
                orig_name = strrep(var_name, '_pre_', '');
                var_dt = additionalInputs_with_memory{i}.getDT();
                [~, zero] = SLX2LusUtils.get_lustre_dt(var_dt);
                if isHeld
                    iterator_body{end+1} = LustreEq(VarIdExpr(var_name), ...
                        BinaryExpr(BinaryExpr.ARROW, ...
                        zero, ...
                        UnaryExpr(UnaryExpr.PRE, VarIdExpr(orig_name))));
                else
                    iterator_body{end+1} = LustreEq(VarIdExpr(var_name), ...
                        zero);
                end
                iterator_variables{end+1} = additionalInputs_with_memory{i};
            end
            
            % add additional outputs to variables list.
            iterator_variables = [iterator_variables, additionalOutputs];
            % start creating the call instances
            function [output_names, input_names] = getOuputsInputs(idx)
                fixed_inputs = cellfun(@(x) ...
                    VarIdExpr(x.getId()),...
                    node_inputs, 'UniformOutput', 0);
                if idx == 1
                    fixed_inputs = [fixed_inputs, ...
                        cellfun(@(x) ...
                        VarIdExpr(x.getId()),...
                        inputsMemory, 'UniformOutput', 0)];
                else
                    fixed_inputs = [fixed_inputs, ...
                        cellfun(@(x) ...
                        VarIdExpr(strrep(x.getId(), '_pre_', '')),...
                        inputsMemory, 'UniformOutput', 0)];
                end
                if IterationLimit == 1
                    additionalInputs_names = cellfun(@(x) ...
                        VarIdExpr(x.getId()),...
                        additionalInputs, 'UniformOutput', 0);
                    output_names = cellfun(@(x) ...
                        VarIdExpr(x.getId()),...
                        main_node_outputs, 'UniformOutput', 0);
                elseif idx == 1
                    additionalInputs_names = cellfun(@(x) ...
                        VarIdExpr(x.getId()),...
                        additionalInputs, 'UniformOutput', 0);
                    
                    output_names = cellfun(@(x) ...
                        VarIdExpr(strcat(x.getId(), '_', num2str(idx))),...
                        main_node_outputs, 'UniformOutput', 0);
                    for vId=1:numel(output_names)
                        iterator_variables{end+1} = LustreVar(...
                            output_names{vId}, ...
                            main_node_outputs{vId}.getDT());
                    end
                elseif idx == IterationLimit
                    additionalInputs_names = cellfun(@(x) ...
                        VarIdExpr(...
                        strcat(...
                        strrep(x.getId(), '_pre_', ''), '_', num2str(idx-1))),...
                        additionalInputs, 'UniformOutput', 0);
                    output_names = cellfun(@(x) ...
                        VarIdExpr(x.getId()),...
                        main_node_outputs, 'UniformOutput', 0);
                else
                    additionalInputs_names = cellfun(@(x) ...
                        VarIdExpr(...
                        strcat(...
                        strrep(x.getId(), '_pre_', ''), '_', num2str(idx-1))),...
                        additionalInputs, 'UniformOutput', 0);
                    output_names = cellfun(@(x) ...
                        VarIdExpr(strcat(x.getId(), '_', num2str(idx))),...
                        main_node_outputs, 'UniformOutput', 0);
                    for vId=1:numel(output_names)
                        iterator_variables{end+1} = LustreVar(...
                            output_names{vId}, ...
                            main_node_outputs{vId}.getDT());
                    end
                end
                input_names = [fixed_inputs, additionalInputs_names];
                if isequal(iteration_dt, 'int')
                    input_names{end} = IntExpr(iterationValue);
                elseif isequal(iteration_dt, 'bool')
                    input_names{end} = BooleanExpr(iterationValue);
                else
                    input_names{end} = RealExpr(iterationValue);
                end
                iterationValue = iterationValue + 1;
                
                
            end
            for i=1:IterationLimit
                [outputs, inputs] = getOuputsInputs(i);
                iterator_body{end+1} = LustreEq(...
                    outputs, NodeCallExpr(main_node.getName(), inputs));
                
            end
            iterator_node.setLocalVars(iterator_variables);
            iterator_node.setBodyEqs(iterator_body);
            
        end
        
        function [new_variables, additionalOutputs, ...
                additionalInputs, inputsMemory] =...
                getForIteratorMemoryVars(variables, node_inputs, memoryIds)
            new_variables = {};
            additionalOutputs = {};
            additionalInputs = {};
            inputsMemory = {};
            variables_names = cellfun(@(x) x.getId(), variables, 'UniformOutput', false);
            node_inputs_names = cellfun(@(x) x.getId(), node_inputs, 'UniformOutput', false);
            memoryIds_names = cellfun(@(x) x.getId(), memoryIds, 'UniformOutput', false);
            for i=1:numel(variables_names)
                if ismember(variables_names{i}, memoryIds_names)
                    additionalOutputs{end+1} = variables{i};
                    additionalInputs{end+1} = LustreVar(strcat('_pre_',...
                        variables_names{i}), variables{i}.getDT());
                else
                    new_variables{end + 1} = variables{i};
                end
            end
            for i=1:numel(node_inputs_names)
                if ismember(node_inputs_names{i}, memoryIds_names)
                    inputsMemory{end+1} = LustreVar(strcat('_pre_',...
                        node_inputs_names{i}), node_inputs{i}.getDT());
                end
            end
        end
        
        %% Statflow support: use old compiler from github
        function [main_node, external_nodes, external_libraries] = ...
                stateflowCode(ss_ir, xml_trace)
            external_nodes = {};
            external_libraries = {};
            rt = sfroot;
            m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name',bdroot(ss_ir.Origin_path));
            chart = m.find('-isa','Stateflow.Chart', 'Path', ss_ir.Origin_path);
            [ char_node, extern_Stateflow_nodes_fun] = write_Chart( chart, 0, xml_trace,'' );
            node_name = get_full_name( chart, true );
            main_node = RawLustreCode(sprintf(char_node), node_name);
            if isempty(extern_Stateflow_nodes_fun)
                return;
            end
            [~, I] = unique({extern_Stateflow_nodes_fun.Name});
            extern_Stateflow_nodes_fun = extern_Stateflow_nodes_fun(I);
            for i=1:numel(extern_Stateflow_nodes_fun)
                fun = extern_Stateflow_nodes_fun(i);
                if strcmp(fun.Name,'trigo')
                    external_libraries{end + 1} = 'LustMathLib_lustrec_math';
                elseif strcmp(fun.Name,'lustre_math_fun')
                    external_libraries{end + 1} = 'LustMathLib_lustrec_math';
                elseif strcmp(fun.Name,'lustre_conv_fun')
                    external_libraries{end + 1} = 'LustDTLib_conv';
                elseif strcmp(fun.Name,'after')
                    external_nodes{end + 1} = RawLustreCode(sprintf(temporal_operators(fun)), 'after');
                elseif strcmp(fun.Name, 'min') && strcmp(fun.Type, 'int*int')
                    external_libraries{end + 1} = 'LustMathLib_min_int';
                elseif strcmp(fun.Name, 'min') && strcmp(fun.Type, 'real*real')
                    external_libraries{end + 1} = 'LustMathLib_min_real';
                elseif strcmp(fun.Name, 'max') && strcmp(fun.Type, 'int*int')
                    external_libraries{end + 1} = 'LustMathLib_max_int';
                elseif strcmp(fun.Name, 'max') && strcmp(fun.Type, 'real*real')
                    external_libraries{end + 1} = 'LustMathLib_max_real';
                end
            end
        end
        
    end
    
end

