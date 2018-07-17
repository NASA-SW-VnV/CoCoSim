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
        function [ main_node, external_nodes, external_libraries ] = ...
                subsystem2node(parent_ir,  ss_ir,  main_sampleTime, ...
                is_main_node, backend, xml_trace)
            %BLOCK_TO_LUSTRE create a lustre node for every Simulink subsystem within
            %subsys_struc.
            %INPUTS:
            %   subsys_struct: The internal representation of the subsystem.
            %   main_clock   : The model sample time.
            
            
            display_msg(['Compiling ', ss_ir.Path], MsgType.INFO, 'subsystem2node', '');
            % Initializing outputs
            external_nodes = '';
            main_node = '';
            external_libraries = {};
            if ~exist('is_main_node', 'var')
                is_main_node = 0;
            end
            
            %% handling Stateflow
            if isfield(ss_ir, 'SFBlockType') && isequal(ss_ir.SFBlockType, 'Chart')
                rt = sfroot;
                m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name',bdroot(ss_ir.Origin_path));
                chart = m.find('-isa','Stateflow.Chart', 'Path', ss_ir.Origin_path);
                [ char_node, chart_external_nodes] = write_Chart( chart, 0, xml_trace,'' );
                main_node = sprintf(char_node);
                external_nodes = sprintf(chart_external_nodes);
                return;
            end
            %%
            isContractBlk = SLX2LusUtils.isContractBlk(ss_ir);
            if isContractBlk && ~BackendType.isKIND2(backend)
                %generate contracts only for KIND2 backend
                return;
            end
            % Adding lustre comments tracking the original path
            origin_path = regexprep(ss_ir.Origin_path, '(\\n|\n)', '--');
            comment = sprintf('-- Original block name: %s', origin_path);
            
            %% creating node header
            
            % The case of Enable/Trigger/Action is handled in the end of this function
            % by creating an additional automaton node.
            isEnableORAction = 0;
            isEnableAndTrigger = 0;
            [node_name, node_inputs_cell, node_outputs_cell,...
                node_inputs_withoutDT_cell, node_outputs_withoutDT_cell] = ...
                SLX2LusUtils.extractNodeHeader(parent_ir, ss_ir, is_main_node,...
                isEnableORAction, isEnableAndTrigger, isContractBlk, ...
                main_sampleTime, xml_trace);
            % concatenate inputs and outputs
            node_inputs = MatlabUtils.strjoin(node_inputs_cell, '\n');
            node_outputs = MatlabUtils.strjoin(node_outputs_cell, '\n');

            
            if isContractBlk
                node_header = sprintf('contract %s (%s)\n returns (%s);',...
                    node_name, node_inputs, node_outputs);
            else
                node_header = sprintf('node %s (%s)\n returns (%s);',...
                    node_name, node_inputs, node_outputs);
            end
            %% Body code
            [body, variables_str, external_nodes, external_libraries] = SS_To_LustreNode.write_body(ss_ir, main_sampleTime, backend, xml_trace);
            if is_main_node
                if ~ismember(SLX2LusUtils.timeStepStr(), node_outputs_withoutDT_cell)
                    if ~isempty(variables_str)
                        variables_str = [variables_str sprintf('\n\t%s:real;', SLX2LusUtils.timeStepStr())];
                    else
                        variables_str = ['var ' sprintf('%s:real;', SLX2LusUtils.timeStepStr())];
                    end
                end
                body = [sprintf('%s = 0.0 -> pre %s + %.15f;\n\t', ...
                    SLX2LusUtils.timeStepStr(), SLX2LusUtils.timeStepStr(), main_sampleTime(1)), body];
                %define all clocks if needed
                clocks = ss_ir.AllCompiledSampleTimes;
                if numel(clocks) > 1
                    c = {};
                    for i=1:numel(clocks)
                        T = clocks{i};
                        st_n = T(1)/main_sampleTime(1);
                        ph_n = T(2)/main_sampleTime(1);
                        if ~((st_n == 1 || st_n == 0 || isinf(st_n) || isnan(st_n))...
                                && (ph_n == 0 || isinf(ph_n) || isnan(ph_n)))
                            body = [sprintf('%s = _make_clock(%.0f, %.0f);\n\t', ...
                                SLX2LusUtils.clockName(st_n, ph_n), st_n, ph_n), body];
                            c{end+1} = SLX2LusUtils.clockName(st_n, ph_n);
                        end
                    end
                    if ~isempty(c)
                        c = MatlabUtils.strjoin(c, ', ');
                        if ~isempty(variables_str)
                            variables_str = [variables_str sprintf('\n\t%s:bool clock;', c)];
                        else
                            variables_str = ['var ' sprintf('%s:bool clock;', c)];
                        end
                        external_libraries{end+1} = '_make_clock';
                    end
                end
            end
            %% Contract
            hasEnablePort = SubSystem_To_Lustre.hasEnablePort(ss_ir);
            hasActionPort = SubSystem_To_Lustre.hasActionPort(ss_ir);
            hasTriggerPort = SubSystem_To_Lustre.hasTriggerPort(ss_ir);
            isConditionalSS = hasEnablePort || hasActionPort || hasTriggerPort;
            % creating contract
            contract = '';
            % the contract of contional SS is done in the automaton node
            if isfield(ss_ir, 'ContractNodeNames')
                contractCell = {};
                contractCell{1} = '(*@contract';
                contractCell{2} = SS_To_LustreNode.getImportedContracts(...
                    parent_ir, ss_ir, main_sampleTime, node_inputs_withoutDT_cell, node_outputs_withoutDT_cell);
               
                contractCell{end+1} = '*)';
                contract = MatlabUtils.strjoin(contractCell, '\n');
            end
            
            
            main_node = sprintf('%s\n%s\n%s\n%s\nlet\n\t%s\ntel\n',...
                comment, node_header, contract, variables_str, body);
            
            if  isConditionalSS
                automaton_node = enabledSubsystem2node(parent_ir, ss_ir, ...
                    hasEnablePort, hasActionPort, hasTriggerPort, isContractBlk, ...
                    main_sampleTime, xml_trace);
                main_node = [main_node, automaton_node];
            end
        end
        
        
        %% Go over SS Content
        function [body, variables_str, external_nodes, external_libraries] =...
                write_body(subsys, main_sampleTime, backend, xml_trace)
            variables_str = '';
            body = '';
            external_nodes = '';
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
                b.write_code(subsys, blk, xml_trace, main_sampleTime, backend);
                body = [body, b.getCode()];
                variables_str = [variables_str, char(MatlabUtils.strjoin(b.variables, '\n\t'))];
                external_nodes = [external_nodes, b.external_nodes];
                external_libraries = [external_libraries, b.external_libraries];
            end
            if ~isempty(variables_str)
                variables_str = ['var ' variables_str];
            end
        end
        
        %% creat import contracts body
        function imported_contracts = getImportedContracts(...
                parent_ir, ss_ir, main_sampleTime, node_inputs_withoutDT, node_outputs_withoutDT)
            % contracts may have differents signature of the node imported
            % in. This function is trying to make the use of contract the most
            % flexible possible. For example having only specific inputs
            % and outputs of the node.
            contractCell = {};
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
                    for i=1:srcBlk.CompiledPortWidths.Outport(x.SrcPort+1)
                        inputs_src_str{end+1} = sprintf('%.5f_%d', x.SrcBlock, x.SrcPort);
                    end
                end
            end
            outputs_src_str = {};
            for i=1:numel(ss_ir.CompiledPortWidths.Outport)
                for j=1:ss_ir.CompiledPortWidths.Outport(i)
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
                        I = I(1:srcBlk.CompiledPortWidths.Outport(SrcPort+1));
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
                contract_inputs = MatlabUtils.strjoin(contract_inputs, ', ');
                contract_outputs =  MatlabUtils.strjoin(contract_outputs, ', ');
                contractCell{end+1} = sprintf('import %s( %s ) returns (%s);', ...
                    ss_ir.ContractNodeNames{i}, contract_inputs, contract_outputs);
            end
            imported_contracts = MatlabUtils.strjoin(contractCell, '\n');
        end
        
    end
    
end

