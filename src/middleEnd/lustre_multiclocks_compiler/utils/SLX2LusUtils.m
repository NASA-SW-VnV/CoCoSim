classdef SLX2LusUtils < handle
    %LUS2UTILS contains all functions that helps in the translation from
    %Simulink to Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods (Static = true)
        %% refactoring names
        function isEnabled = isEnabledStr()
            isEnabled = '_isEnabled';
        end
        function isEnabled = isTriggeredStr()
            isEnabled = '_isTriggered';
        end
        function time_step = timeStepStr()
            time_step = '__time_step';
        end
        function time_step = nbStepStr()
            time_step = '__nb_step';
        end
        function it = iterationVariable()
            it = '_iterationVariable';
        end
        function res = isContractBlk(ss_ir)
            res = isfield(ss_ir, 'MaskType') ...
                && strcmp(ss_ir.MaskType, 'ContractBlock');
        end
        %% adapt blocks names to be a valid lustre names.
        function str_out = name_format(str)
            str_out = strrep(str, newline, '');
            str_out = regexprep(str_out, '^\s', '_');
            str_out = regexprep(str_out, '\s$', '_');
            str_out = strrep(str_out, ' ', '');
            str_out = strrep(str_out, '-', '_minus_');
            str_out = strrep(str_out, '+', '_plus_');
            str_out = strrep(str_out, '*', '_mult_');
            str_out = strrep(str_out, '>', '_gt_');
            str_out = strrep(str_out, '>=', '_gte_');
            str_out = strrep(str_out, '<', '_lt_');
            str_out = strrep(str_out, '<=', '_lte_');
            str_out = strrep(str_out, '.', '_dot_');
            str_out = strrep(str_out, '#', '_sharp_');
            str_out = strrep(str_out, '(', '_lpar_');
            str_out = strrep(str_out, ')', '_rpar_');
            str_out = strrep(str_out, '[', '_lsbrak_');
            str_out = strrep(str_out, ']', '_rsbrak_');
            str_out = strrep(str_out, '{', '_lbrak_');
            str_out = strrep(str_out, '}', '_rbrak_');
            str_out = strrep(str_out, ',', '_comma_');
            %             str_out = strrep(str_out, '/', '_slash_');
            str_out = strrep(str_out, '=', '_equal_');
            % for blocks starting with a digit.
            str_out = regexprep(str_out, '^(\d+)', 'x$1');
            str_out = regexprep(str_out, '/(\d+)', '/_$1');
            % for anything missing from previous cases.
            str_out = regexprep(str_out, '[^a-zA-Z0-9_/]', '_');
        end
        
        
        %% Lustre node name from a simulink block name. Here we choose only
        %the name of the block concatenated to its handle to be unique
        %name.
        function node_name = node_name_format(subsys_struct)
            if isempty(strfind(subsys_struct.Path, filesep))
                % main node: should be the same as filename
                node_name = SLX2LusUtils.name_format(subsys_struct.Name);
            else
                handle_str = strrep(sprintf('%.3f', subsys_struct.Handle), '.', '_');
                node_name = sprintf('%s_%s',SLX2LusUtils.name_format(subsys_struct.Name),handle_str );
            end
        end
        
        %% Lustre node inputs, outputs
        function [node_name,  node_inputs_cell, node_outputs_cell,...
                node_inputs_withoutDT_cell, node_outputs_withoutDT_cell ] = ...
                extractNodeHeader(parent_ir, blk, is_main_node, ...
                isEnableORAction, isEnableAndTrigger, isContractBlk, ...
                main_sampleTime, xml_trace)
            % this function is used to get the Lustre node inputs and
            % outputs.
            
            
            % creating node header
            node_name = SLX2LusUtils.node_name_format(blk);
            
            
            % contract handling
            if isContractBlk
                [ node_inputs_cell, node_outputs_cell,...
                    node_inputs_withoutDT_cell, node_outputs_withoutDT_cell ] = ...
                    SLX2LusUtils.extractContractHeader(parent_ir, blk, main_sampleTime, xml_trace);
                return;
            end
             % create traceability
            xml_trace.create_Node_Element(blk.Origin_path, node_name,...
                SLX2LusUtils.isContractBlk(blk)); % not using isContractBlk 
            %variable because it may be 0 if the functions is called from SLX2LusUtils.extractContractHeader
            
            
            %creating inputs
            xml_trace.create_Inputs_Element();
            [node_inputs_cell, node_inputs_withoutDT_cell] = ...
                SLX2LusUtils.extract_node_InOutputs_withDT(blk, 'Inport', xml_trace);
            
            % add the execution condition if it is a conditionally executed
            % SS
            if isEnableORAction
                node_inputs_cell{end + 1} = LustreVar(...
                    SLX2LusUtils.isEnabledStr() , 'bool');
                % we don't include them in node_inputs_withoutDT_cell, see
                % condExecSS_To_LusAutomaton
                %node_inputs_withoutDT_cell{end + 1} = VarIdExpr(...
                %    SLX2LusUtils.isEnabledStr());
            elseif isEnableAndTrigger
                node_inputs_cell{end + 1} = LustreVar(...
                    SLX2LusUtils.isEnabledStr() , 'bool');
                % we don't include them in node_inputs_withoutDT_cell, see
                % condExecSS_To_LusAutomaton
                %node_inputs_withoutDT_cell{end + 1} = VarIdExpr(...
                %    SLX2LusUtils.isEnabledStr());
                node_inputs_cell{end + 1} = LustreVar(...
                    SLX2LusUtils.isTriggeredStr() , 'bool');
                % we don't include them in node_inputs_withoutDT_cell, see
                % condExecSS_To_LusAutomaton
                %node_inputs_withoutDT_cell{end + 1} = VarIdExpr(...
                %    SLX2LusUtils.isTriggeredStr());
            end
            %add simulation time input and clocks
            if ~is_main_node
                [node_inputs_cell, node_inputs_withoutDT_cell] = ...
                SLX2LusUtils.getTimeClocksInputs(blk, main_sampleTime, node_inputs_cell, node_inputs_withoutDT_cell);
            end
            % if the node has no inputs, add virtual input for Lustrec.
            if isempty(node_inputs_cell)
                node_inputs_cell{end + 1} = LustreVar('_virtual', 'bool');
                node_inputs_withoutDT_cell{end+1} = VarIdExpr('_virtual');
            end
           
            % creating outputs
            xml_trace.create_Outputs_Element();
            [node_outputs_cell, node_outputs_withoutDT_cell] =...
                SLX2LusUtils.extract_node_InOutputs_withDT(blk, 'Outport', xml_trace);
            
            if is_main_node && isempty(node_outputs_cell)
                node_outputs_cell{end+1} = LustreVar(...
                    SLX2LusUtils.timeStepStr(), 'real');
                node_outputs_withoutDT_cell{end+1} = VarIdExpr(SLX2LusUtils.timeStepStr());
            end
        end
        
        function [names, names_withNoDT] = extract_node_InOutputs_withDT(subsys, type, xml_trace)
            %get all blocks names
            fields = fieldnames(subsys.Content);
            
            % remove blocks without BlockType (e.g annotations)
            fields = ...
                fields(...
                cellfun(@(x) isfield(subsys.Content.(x),'BlockType'), fields));
            
            % get only blocks with BlockType=type
            Portsfields = ...
                fields(...
                cellfun(@(x) strcmp(subsys.Content.(x).BlockType,type), fields));
            
            isInsideContract = SLX2LusUtils.isContractBlk(subsys);
            % sort the blocks by order of their ports
            ports = cellfun(@(x) str2num(subsys.Content.(x).Port), Portsfields);
            [~, I] = sort(ports);
            Portsfields = Portsfields(I);
            names = {};
            names_withNoDT = {};
            for i=1:numel(Portsfields)
                block = subsys.Content.(Portsfields{i});
                [names_withNoDT_i, names_i] = SLX2LusUtils.getBlockOutputsNames(subsys, block);
                names = [names, names_i];
                names_withNoDT = [names_withNoDT, names_withNoDT_i];
                % traceability
                width = numel(names_withNoDT_i);
                IsNotInSimulink = false;
                for index=1:numel(names_withNoDT_i)
                    xml_trace.add_InputOutputVar( type, names_withNoDT_i{index}.getId(), ...
                        block.Origin_path, 1, width, index, isInsideContract, IsNotInSimulink);
                end
            end
            if strcmp(type, 'Inport')
                % add enable port to the node inputs, if ShowOutputPort is
                % on
                enablePortsFields = fields(...
                    cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'EnablePort'), fields));
                if ~isempty(enablePortsFields) ...
                        && strcmp(subsys.Content.(enablePortsFields{1}).ShowOutputPort, 'on')
                    [names_withNoDT_i, names_i] = SLX2LusUtils.getBlockOutputsNames(subsys, subsys.Content.(enablePortsFields{1}));
                    names = [names, names_i];
                    names_withNoDT = [names_withNoDT, names_withNoDT_i];
                    % traceability
                    width = numel(names_withNoDT_i);
                    IsNotInSimulink = false;
                    block = subsys.Content.(enablePortsFields{1});
                    for index=1:numel(names_withNoDT_i)
                        xml_trace.add_InputOutputVar( type, names_withNoDT_i{index}.getId(), ...
                            block.Origin_path, 1, width, index, isInsideContract, IsNotInSimulink);
                    end
                end
                % add trigger port to the node inputs, if ShowOutputPort is
                % on
                triggerPortsFields = fields(...
                    cellfun(@(x) strcmp(subsys.Content.(x).BlockType,'TriggerPort'), fields));
                if ~isempty(triggerPortsFields) ...
                        && strcmp(subsys.Content.(triggerPortsFields{1}).ShowOutputPort, 'on')
                    [names_withNoDT_i, names_i] = SLX2LusUtils.getBlockOutputsNames(subsys, subsys.Content.(triggerPortsFields{1}));
                    names = [names, names_i];
                    names_withNoDT = [names_withNoDT, names_withNoDT_i];
                    % traceability
                    width = numel(names_withNoDT_i);
                    IsNotInSimulink = false;
                    block = subsys.Content.(triggerPortsFields{1});
                    for index=1:numel(names_withNoDT_i)
                        xml_trace.add_InputOutputVar( type, names_withNoDT_i{index}.getId(), ...
                            block.Origin_path, 1, width, index, isInsideContract, IsNotInSimulink);
                    end
                end
            end
            
        end
        function [node_inputs_cell, node_inputs_withoutDT_cell] = ...
                getTimeClocksInputs(blk, main_sampleTime, node_inputs_cell, node_inputs_withoutDT_cell)
            node_inputs_cell{end + 1} = LustreVar(...
                SLX2LusUtils.timeStepStr(), 'real');
            node_inputs_withoutDT_cell{end+1} = ...
                VarIdExpr(SLX2LusUtils.timeStepStr());
            node_inputs_cell{end + 1} = LustreVar(...
                SLX2LusUtils.nbStepStr(), 'int');
            node_inputs_withoutDT_cell{end+1} = ...
                VarIdExpr(SLX2LusUtils.nbStepStr());
            % add clocks
            clocks_list = SLX2LusUtils.getRTClocksSTR(blk, main_sampleTime);
            if ~isempty(clocks_list)
                for i=1:numel(clocks_list)
                    node_inputs_cell{end + 1} = LustreVar(...
                        clocks_list{i}, 'bool clock');
                    node_inputs_withoutDT_cell{end+1} = VarIdExpr(...
                        clocks_list{i});
                end
            end
        end
        %% Contract header
        function [node_inputs, node_outputs, ...
                    node_inputs_withoutDT, node_outputs_withoutDT ] = ...
                    extractContractHeader(parent_ir, contract, main_sampleTime, xml_trace)
                % This function is creating the header of the contract.
                % A contract is different from a node by having the same
                % signature of the abstracted node. So we need to divide
                % the actual Contracts inputs to inputs and outputs to
                % match the abstracted node associated to. We can also
                % allow a contract that does not take all inputs/outputs of
                % the abstracted node by extending it's signature with
                % unused inputs/outputs.
                % The order of inputs in contract in Simulink may have
                % different order from the verified SS.
                node_inputs = {};
                node_outputs = {};
                node_inputs_withoutDT = {};
                node_outputs_withoutDT = {};
                % Get the actual inputs of Contract block as a simple SS
                is_main_node = 0; isEnableORAction=0; isEnableAndTrigger=0;
                isContractBlk = 0;
                [~, contract_inputs, contract_outputs, ...
                    contract_inputs_withoutDT, contract_outputs_withoutDT ] = ...
                    SLX2LusUtils.extractNodeHeader(parent_ir, contract, is_main_node, ...
                    isEnableORAction, isEnableAndTrigger, isContractBlk, main_sampleTime, xml_trace);
                %change
                % get Associated SS
                if ~isfield(contract, 'AssociatedBlkHandle')
                    display_msg(sprintf('Can not find AssociatedBlkHandle parameter in contract %s.', ...
                        contract.Origin_path), MsgType.DEBUG, 'extractContractHeader', '');
                    % keep the same contract signature
                    node_inputs = contract_inputs;
                    node_outputs = contract_outputs;
                    node_inputs_withoutDT = contract_inputs_withoutDT;
                    node_outputs_withoutDT = contract_outputs_withoutDT;
                    return;
                end
                % we assume PortConnectivity is ordered by the graphical
                % order of inputs.
                associatedBlkHandle = contract.AssociatedBlkHandle;
                associatedBlk = get_struct(parent_ir, associatedBlkHandle);
                if isempty(associatedBlk)
                    display_msg(sprintf('Can not find AssociatedBlkHandle parameter in contract %s.', ...
                        contract.Origin_path), MsgType.DEBUG, 'extractContractHeader', '');
                    % keep the same contract signature
                    node_inputs = contract_inputs;
                    node_outputs = contract_outputs;
                    node_inputs_withoutDT = contract_inputs_withoutDT;
                    node_outputs_withoutDT = contract_outputs_withoutDT;
                    return;
                end
                curr_idx = 1;
                for j=1:numel(contract.PortConnectivity)
                    srcBlkHandle = contract.PortConnectivity(j).SrcBlock;
                    if isempty(srcBlkHandle)
                        % skip "valid" output
                        continue;
                    end
                    SrcPort = contract.PortConnectivity(j).SrcPort;
                    if srcBlkHandle ~= associatedBlkHandle
                        srcBlk = get_struct(parent_ir, srcBlkHandle);
                        if isempty(srcBlk)
                            continue;
                        end
                        % input
                        %get actual size after inlining.
                        [names, ~] = SLX2LusUtils.getBlockOutputsNames(...
                            parent_ir, srcBlk, SrcPort);
                        for i=1:numel(names)
                            node_inputs{end + 1} = contract_inputs{curr_idx};
                            node_inputs_withoutDT{end+1} =...
                                contract_inputs_withoutDT{curr_idx};
                            curr_idx = curr_idx + 1;
                        end
                    else
                        % output
                        [names, ~] = SLX2LusUtils.getBlockOutputsNames(...
                            parent_ir, associatedBlk, SrcPort);
                        for i=1:numel(names)
                            node_outputs{end + 1} = contract_inputs{curr_idx};
                            node_outputs_withoutDT{end+1} =...
                                contract_inputs_withoutDT{curr_idx};
                            curr_idx = curr_idx + 1;
                        end
                    end
                end
                % add additional inputs such as simulation time and clocks
                for i=curr_idx:numel(contract_inputs)
                    node_inputs{end + 1} = contract_inputs{i};
                    node_inputs_withoutDT{end+1} =...
                        contract_inputs_withoutDT{i};
                end
                
        end
        %% get If the "blk" is the one abstracted by "contract"
        % to use is, blk and contract are objects
        function res = isAbstractedByContract(blk, contract)
            if ischar(blk) || isnumeric(blk)
                try
                    blk = get_param(blk, 'Object');
                catch me
                    display_msg('Function SLX2LustUtils.isAbstractedByContract should be called over structures',...
                        MsgType.ERROR, 'SLX2LustUtils.isAbstractedByContract', '');
                    display_msg(me.getReport(),...
                        MsgType.DEBUG, 'SLX2LustUtils.isAbstractedByContract', '');
                end
            end
            if ischar(contract) || isnumeric(contract)
                try
                    contract = get_param(contract, 'Object');
                catch me
                    display_msg('Function SLX2LustUtils.isAbstractedByContract should be called over structures',...
                        MsgType.ERROR, 'SLX2LustUtils.isAbstractedByContract', '');
                    display_msg(me.getReport(),...
                        MsgType.DEBUG, 'SLX2LustUtils.isAbstractedByContract', '');
                end
            end
            blk_connextivity_str = {};
            dstPort = 0;
            for j=1:numel(blk.PortConnectivity)
                x = blk.PortConnectivity(j);
                if isempty(x.SrcBlock)
                    % SrcBlock will be the blk itself and SrcPort is Type atribute
                    blk_connextivity_str{end+1} = sprintf('%.5f_%d', blk.Handle, dstPort);
                    dstPort = dstPort + 1;
                else
                    blk_connextivity_str{end+1} = sprintf('%.5f_%d', x.SrcBlock, x.SrcPort);
                end
            end
            
            contract_connextivity_str = {};
            for j=1:numel(contract.PortConnectivity)
                x = contract.PortConnectivity(j);
                if isempty(x.SrcBlock)
                    continue;
                else
                    contract_connextivity_str{end+1} = sprintf('%.5f_%d', x.SrcBlock, x.SrcPort);
                end
            end
            res = ~any(~ismember(contract_connextivity_str, blk_connextivity_str));
        end
        %% get block outputs names: inlining dimension
        function [names, names_dt] = getBlockOutputsNames(parent, blk, ...
                srcPort, xml_trace)
            % This function return the names of the block
            % outputs.
            % Example : an Inport In with dimension [2, 3] will be
            % translated as : In_1, In_2, In_3, In_4, In_5, In_6.
            % where In_1 = In(1,1), In_2 = In(2,1), In_3 = In(1,2),
            % In_4 = In(2,2), In_5 = In(1,3), In_6 = In(2,3).
            % A block is defined by its outputs, if a block does not
            % have outports, like Outport block, than will be defined by its
            % inports. E.g, Outport Out with width 2 -> Out_1, out_2
            blksNamesDefinedByTheirInports = {'Outport', 'Goto'};
            needToLogTraceability = 0;
            if nargin > 3
                % this function is only called with "xml_trace" variable in
                % Block_To_Lustre classes. 
                needToLogTraceability = 1;
            end
            names = {};
            names_dt = {};
            if isempty(blk) ...
                    || (isempty(blk.CompiledPortWidths.Outport) ...
                    && isempty(blk.CompiledPortWidths.Inport))
                return;
            end
            % case of block with 'auto' Type, we need to get the inports
            % datatypes.
            if numel(blk.CompiledPortDataTypes.Outport) == 1 ...
                    && strcmp(blk.CompiledPortDataTypes.Outport{1}, 'auto') ...
                    && ~isempty(blk.CompiledPortWidths.Inport)...
                    && ~isequal(blk.BlockType, 'SubSystem') 
                
                if numel(blk.CompiledPortWidths.Inport) > 1 ...
                        && isequal(blk.BlockType, 'BusCreator') 
                    % e,g BusCreator DT is defined by all its inputs
                    width = blk.CompiledPortWidths.Inport;
                else
                    % e,g BusAssignment and other blocks DT are
                    % defined by their first input
                    width = blk.CompiledPortWidths.Inport(1);
                end
                type = 'Inports';
                
            elseif isempty(blk.CompiledPortWidths.Outport) ...
                    && ismember(blk.BlockType, blksNamesDefinedByTheirInports)
                width = blk.CompiledPortWidths.Inport;
                type = 'Inports';
            else
                width = blk.CompiledPortWidths.Outport;
                type = 'Outports';
            end
            
            function [names, names_dt] = blockOutputs(portNumber)
                names = {};
                names_dt = {};
                if strcmp(type, 'Inports')
                    slx_dt = blk.CompiledPortDataTypes.Inport{portNumber};
                else
                    slx_dt = blk.CompiledPortDataTypes.Outport{portNumber};
                end
                if strcmp(slx_dt, 'auto')
                    if strcmp(type, 'Inports')
                        % this is the case of virtual bus, we need to do back
                        % propagation to find the real datatypes
                        if isfield(blk, 'BusObject') && ~isempty(blk.BusObject)
                            isBus = SLXUtils.isSimulinkBus(blk.BusObject);
                            
                            if isBus
                                lus_dt =...
                                    SLX2LusUtils.getLustreTypesFromBusObject(blk.BusObject);
                                isBus = false;
                            else
                                lus_dt = SLX2LusUtils.getpreBlockLusDT(parent, blk, portNumber);
                            end
                        else
                            lus_dt = SLX2LusUtils.getpreBlockLusDT(parent, blk, portNumber);
                            isBus = false;
                        end
                    elseif isequal(blk.BlockType, 'SubSystem') 
                        %get all blocks names
                        fields = fieldnames(blk.Content);
                        
                        % remove blocks without BlockType (e.g annotations)
                        fields = ...
                            fields(...
                            cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
                        
                        % get only blocks with BlockType=type
                        Portsfields = ...
                            fields(...
                            cellfun(@(x) strcmp(blk.Content.(x).BlockType,'Outport'), fields));
                        % get their ports number
                        ports = cellfun(@(x) str2num(blk.Content.(x).Port), Portsfields);
                        outportBlk = blk.Content.(Portsfields{ports == portNumber});
                        lus_dt = SLX2LusUtils.getpreBlockLusDT( blk, outportBlk, 1);
                        isBus = false;
                    else
                        try
                            pH = get_param(blk.Origin_path, 'PortHandles');
                            SignalHierarchy = get_param(pH.Outport(portNumber), ...
                                'SignalHierarchy');
                            [lus_dt] = SLX2LusUtils.SignalHierarchyLusDT(...
                                blk, SignalHierarchy); 
                            isBus = false;
                        catch me
                            display_msg(me.getReport(), MsgType.DEBUG, 'getBlockOutputsNames', '');
                            lus_dt = 'real';
                            isBus = false;
                        end
                        
                    end
                else
                    [lus_dt, ~, ~, isBus] = SLX2LusUtils.get_lustre_dt(slx_dt);
                end
                % The width should start from the port width regarding all
                % subsystem outputs
                idx = sum(width(1:portNumber-1))+1;
                for i=1:width(portNumber)
                    if isBus
                        for k=1:numel(lus_dt)
                            names{end+1} = VarIdExpr(...
                                SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx), '_BusElem', num2str(k))));
                            names_dt{end+1} = LustreVar(names{end} , lus_dt{k});
                        end
                    elseif iscell(lus_dt) && numel(lus_dt) == width(portNumber)
                        names{end+1} = VarIdExpr(...
                            SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx))));
                        names_dt{end+1} = LustreVar(names{end}, char(lus_dt{i}));
                    else
                        names{end+1} = VarIdExpr(...
                            SLX2LusUtils.name_format(strcat(blk.Name, '_', num2str(idx))));
                        names_dt{end+1} = LustreVar(names{end}, char(lus_dt));
                    end
                    idx = idx + 1;
                end
            end
            isInsideContract = SLX2LusUtils.isContractBlk(parent);
            IsNotInSimulink = false;
            if nargin >= 3 && ~isempty(srcPort)...
                    && ~strcmp(blk.CompiledPortDataTypes.Outport{srcPort + 1}, 'auto')
                port = srcPort + 1;% srcPort starts by zero
                [names, names_dt] = blockOutputs(port);
                 % traceability
                 if needToLogTraceability
                     for index=1:numel(names)
                         xml_trace.add_InputOutputVar( 'Variable', names{index}.getId(), ...
                             blk.Origin_path, port, numel(names), index, isInsideContract, IsNotInSimulink);
                     end
                 end
            else
                for port=1:numel(width)
                    [names_i, names_dt_i] = blockOutputs(port);
                    names = [names, names_i];
                    names_dt = [names_dt, names_dt_i];
                    if needToLogTraceability
                        for index=1:numel(names_i)
                            xml_trace.add_InputOutputVar( 'Variable', names_i{index}.getId(), ...
                                blk.Origin_path, port, numel(names_i), index, isInsideContract, IsNotInSimulink);
                        end
                    end
                end
            end
        end
        %%
        function [lus_dt] = SignalHierarchyLusDT(blk, SignalHierarchy)
            %isBus = false;
            lus_dt = {};
            try
                if ~isfield(SignalHierarchy, 'SignalName')
                    display_msg(sprintf('Bock %s has an auto dataType and is not supported',...
                    blk.Origin_path), MsgType.ERROR, '', '');
                    lus_dt = 'real';
                    return;
                end
                SignalName = SignalHierarchy.SignalName;
                if isempty(SignalHierarchy.SignalName)
                    SignalName = SignalHierarchy.BusObject;
                end
                if isempty(SignalName)
                    if  ~isfield(SignalHierarchy, 'Children') ...
                            || isempty(SignalHierarchy.Children)
                        lus_dt = 'real';
                        display_msg(sprintf('Bock %s has an auto dataType and is not supported',...
                            blk.Origin_path), MsgType.ERROR, '', '');
                        return;
                    else
                        for i=1:numel(SignalHierarchy.Children)
                            [lus_dt_i] = ...
                                SLX2LusUtils.SignalHierarchyLusDT(blk, SignalHierarchy.Children(i));
                            if iscell(lus_dt_i)
                                lus_dt = [lus_dt, lus_dt_i];
                            else
                                lus_dt{end+1} = lus_dt_i;
                            end
                        end
                        return;
                    end
                end
                isBus = SLXUtils.isSimulinkBus(SignalName);
                if isBus
                    lus_dt =...
                        SLX2LusUtils.getLustreTypesFromBusObject(SignalName);
                else
                    p = find_system(bdroot(blk.Origin_path),...
                        'FindAll', 'on', ...
                        'Type', 'port',...
                        'PortType', 'outport', ...
                        'SignalNameFromLabel', SignalName );
                    BusCreatorFound = false;
                    for i=1:numel(p)
                        p_parent=  get_param(p(i), 'Parent');
                        p_parentObj = get_param(p_parent, 'Object');
                        if isequal(p_parentObj.BlockType, 'BusCreator')
                            BusCreatorFound = true;
                            break;
                        end
                    end
                    if BusCreatorFound
                        lus_dt = SLX2LusUtils.getBusCreatorLusDT(...
                            get_param(p_parentObj.Parent, 'Object'), ...
                            p_parentObj, ...
                            get_param(p(i), 'PortNumber'));
                    elseif numel(p) >= 1
                        compiledDT = SLXUtils.getCompiledParam(p(1), 'CompiledPortDataType');
                        [lus_dt, ~, ~, ~] = ...
                            SLX2LusUtils.get_lustre_dt(compiledDT);
                        CompiledPortWidth = SLXUtils.getCompiledParam(p(1), 'CompiledPortWidth');
                        if iscell(lus_dt) && numel(lus_dt) < CompiledPortWidth
                            lus_dt = arrayfun(@(x) lus_dt{1}, (1:CompiledPortWidth), ...
                                'UniformOutput', 0);
                        else
                            lus_dt = arrayfun(@(x) lus_dt, (1:CompiledPortWidth), ...
                                'UniformOutput', 0);
                        end
                    else
                        lus_dt = 'real';
                    end
                end
            catch me
                display_msg(me.getReport(), MsgType.DEBUG, 'getBlockOutputsNames', '');
                lus_dt = 'real';
            end
        end
        %% get block inputs names. E.g subsystem taking input signals from differents blocks.
        % We need to go over all linked blocks and get their output names
        % in the corresponding port number.
        % Read PortConnectivity documentation for more information.
        function [inputs] = getBlockInputsNames(parent, blk, Port)
            % get only inports, we don't take enable/reset/trigger, outputs
            % ports.
            srcPorts = blk.PortConnectivity(...
                arrayfun(@(x) ~isempty(x.SrcBlock) ...
                &&  ~isempty(str2num(x.Type)) , blk.PortConnectivity));
            if nargin >= 3 && ~isempty(Port)
                srcPorts = srcPorts(Port);
            end
            inputs = {};
            for b=srcPorts'
                srcPort = b.SrcPort;
                srcHandle = b.SrcBlock;
                src = get_struct(parent, srcHandle);
                if isempty(src)
                    continue;
                end
                n_i = SLX2LusUtils.getBlockOutputsNames(parent, src, srcPort);
                inputs = [inputs, n_i];
            end
        end
        function [inputs] = getSubsystemEnableInputsNames(parent, blk)
            [inputs] = SLX2LusUtils.getSpecialInputsNames(parent, blk, 'enable');
        end
        function [inputs] = getSubsystemTriggerInputsNames(parent, blk)
            [inputs] = SLX2LusUtils.getSpecialInputsNames(parent, blk, 'trigger');
        end
        function [inputs] = getSubsystemResetInputsNames(parent, blk)
            [inputs] = SLX2LusUtils.getSpecialInputsNames(parent, blk, 'Reset');
        end
        function [inputs] = getSpecialInputsNames(parent, blk, type)
            srcPorts = blk.PortConnectivity(...
                arrayfun(@(x) strcmp(x.Type, type), blk.PortConnectivity));
            inputs = {};
            for b=srcPorts'
                srcPort = b.SrcPort;
                srcHandle = b.SrcBlock;
                src = get_struct(parent, srcHandle);
                if isempty(src)
                    continue;
                end
                n_i = SLX2LusUtils.getBlockOutputsNames(parent, src, srcPort);
                inputs = [inputs, n_i];
            end
        end
        %% get pre block for specific port number
        function [src, srcPort] = getpreBlock(parent, blk, Port)
            
            if ischar(Port)
                % case of Type: ifaction ...
                srcBlk = blk.PortConnectivity(...
                    arrayfun(@(x) strcmp(x.Type, Port), blk.PortConnectivity));
            else
                srcBlks = blk.PortConnectivity(...
                    arrayfun(@(x) ~isempty(x.SrcBlock), blk.PortConnectivity));
                srcBlk = srcBlks(Port);
            end
            if isempty(srcBlk)
                src = [];
                srcPort = [];
            else
                % Simulink srcPort starts from 0, we add one.
                srcPort = srcBlk.SrcPort + 1;
                srcHandle = srcBlk.SrcBlock;
                src = get_struct(parent, srcHandle);
            end
        end
        %% get pre block DataType for specific port,
        %it is used in the case of 'auto' type.
        function lus_dt = getpreBlockLusDT(parent, blk, portNumber)
           
            global model_struct
            lus_dt = {};
            if strcmp(blk.BlockType, 'Inport')
                
                if ~isempty(model_struct)
                    portNumber = str2num(blk.Port);
                    blk = parent;
                    parent = model_struct;
                end
            end
            [srcBlk, blkOutportPort] = SLX2LusUtils.getpreBlock(parent, blk, portNumber);
            
            if isempty(srcBlk)
                lus_dt = {'real'};
                display_msg(sprintf('Bock %s has an auto dataType and is not supported',...
                    srcBlk.Origin_path), MsgType.ERROR, '', '');
                return;
            end
            if strcmp(srcBlk.CompiledPortDataTypes.Outport{blkOutportPort}, 'auto')
                lus_dt = SLX2LusUtils.getBusCreatorLusDT(parent, srcBlk, blkOutportPort);
            else
                width = srcBlk.CompiledPortWidths.Outport;
                slx_dt = srcBlk.CompiledPortDataTypes.Outport{blkOutportPort};
                lus_dt_tmp = SLX2LusUtils.get_lustre_dt(slx_dt);
                if iscell(lus_dt_tmp)
                    lus_dt = [lus_dt, lus_dt_tmp];
                else
                    lus_dt_tmp = cellfun(@(x) {lus_dt_tmp}, (1:width(blkOutportPort)), 'UniformOutput',false);
                    lus_dt = [lus_dt, lus_dt_tmp];
                end
            end
        end
        function lus_dt = getBusCreatorLusDT(parent, srcBlk, portNumber)
            lus_dt = {};
            if strcmp(srcBlk.BlockType, 'BusCreator')
                width = srcBlk.CompiledPortWidths.Inport;
                for port=1:numel(width)
                    slx_dt = srcBlk.CompiledPortDataTypes.Inport{port};
                    if strcmp(slx_dt, 'auto')
                        lus_dt = [lus_dt, ...
                            SLX2LusUtils.getpreBlockLusDT(parent, srcBlk, port)];
                    else
                        lus_dt_tmp = SLX2LusUtils.get_lustre_dt(slx_dt);
                        if iscell(lus_dt_tmp)
                            lus_dt = [lus_dt, lus_dt_tmp];
                        else
                            lus_dt_tmp = arrayfun(@(x) {lus_dt_tmp}, (1:width(port)), 'UniformOutput',false);
                            lus_dt = [lus_dt, lus_dt_tmp];
                        end
                    end
                end
            else
                pH = get_param(srcBlk.Origin_path, 'PortHandles');
                SignalHierarchy = get_param(pH.Outport(portNumber), ...
                    'SignalHierarchy');
                [lus_dt] = SLX2LusUtils.SignalHierarchyLusDT(...
                    srcBlk,  SignalHierarchy);
            end
        end
        %% Change Simulink DataTypes to Lustre DataTypes. Initial default
        %value is also given as a string.
        function [ Lustre_type, zero, one, isBus ] = get_lustre_dt( slx_dt)
            isBus = false;
            if strcmp(slx_dt, 'real') || strcmp(slx_dt, 'int') || strcmp(slx_dt, 'bool')
                Lustre_type = slx_dt;
            else
                if strcmp(slx_dt, 'logical') || strcmp(slx_dt, 'boolean') || strcmp(slx_dt, 'action')
                    Lustre_type = 'bool';
                elseif strncmp(slx_dt, 'int', 3) || strncmp(slx_dt, 'uint', 4) || strncmp(slx_dt, 'fixdt(1,16,', 11) || strncmp(slx_dt, 'sfix64', 6)
                    Lustre_type = 'int';
                elseif strcmp(slx_dt, 'double') || strcmp(slx_dt, 'single')
                    Lustre_type = 'real';
                else
                    % considering enumaration as int
                    m = evalin('base', sprintf('enumeration(''%s'')',char(slx_dt)));
                    if isempty(m)
                        isBus = SLXUtils.isSimulinkBus(char(slx_dt));
                        
                        if isBus
                            Lustre_type = SLX2LusUtils.getLustreTypesFromBusObject(char(slx_dt));
                        else
                            Lustre_type = 'real';
                        end
                    else
                        % considering enumaration as int
                        Lustre_type = 'int';
                    end
                    
                end
            end
            if iscell(Lustre_type)
                zero = {};
                one = {};
                for i=1:numel(Lustre_type)
                    if strcmp(Lustre_type{i}, 'bool')
                        zero{i} = BooleanExpr('false');
                        one{i} = BooleanExpr('true') ;
                    elseif strcmp(Lustre_type{i}, 'int')
                        zero{i} = IntExpr('0');
                        one{i} = IntExpr('1');
                    else
                        zero{i} = RealExpr('0.0');
                        one{i} = RealExpr('1.0');
                    end
                end
            else
                if strcmp(Lustre_type, 'bool')
                    zero = BooleanExpr('false');
                    one = BooleanExpr('true');
                elseif strcmp(Lustre_type, 'int')
                    zero = IntExpr('0');
                    one = IntExpr('1');
                else
                    zero = RealExpr('0.0');
                    one = RealExpr('1.0');
                end
            end
        end
        
        %% Bus signal Lustre dataType
        function lustreTypes = getLustreTypesFromBusObject(busName)
            bus = evalin('base', char(busName));
            lustreTypes = {};
            try
                elems = bus.Elements;
            catch
                % Elements is not in bus.
                return;
            end
            for i=1:numel(elems)
                dt = elems(i).DataType;
                dimensions = elems(i).Dimensions;
                width = prod(dimensions);
                if strncmp(dt, 'Bus:', 4)
                    dt = regexprep(dt, 'Bus:\s*', '');
                end
                lusDT = SLX2LusUtils.get_lustre_dt( dt);
                for w=1:width
                    if iscell(lusDT)
                        lustreTypes = [lustreTypes, lusDT];
                    else
                        lustreTypes{end+1} = lusDT;
                    end
                end
            end
        end
        
        function in_matrix_dimension = getDimensionsFromBusObject(busName)
            in_matrix_dimension = {};
            bus = evalin('base', char(busName));
            try
                elems = bus.Elements;
            catch
                % Elements is not in bus.
                return;
            end
            for i=1:numel(elems)
                dt = elems(i).DataType;
                dt = strrep(dt, 'Bus: ', '');
                isBus = SLXUtils.isSimulinkBus(char(dt));
                
                if isBus
                    dt = regexprep(dt, 'Bus:\s*', '');
                    in_matrix_dimension = [in_matrix_dimension,...
                        SLX2LusUtils.getDimensionsFromBusObject(dt)];
                else
                    dimensions = elems(i).Dimensions;
                    idx = numel(in_matrix_dimension) +1;
                    in_matrix_dimension{idx}.dims = dimensions;
                    in_matrix_dimension{idx}.width = prod(dimensions);
                    in_matrix_dimension{idx}.numDs = numel(dimensions);
                end
            end
        end
        
        %% Get the initial ouput of Outport depending on the dimension.
        % the function returns a list of LustreExp objects: IntExpr,
        % RealExpr or BooleanExpr
        function InitialOutput_cell = getInitialOutput(parent, blk, InitialOutput, slx_dt, max_width)
            [lus_outputDataType] = SLX2LusUtils.get_lustre_dt(slx_dt);
            if strcmp(InitialOutput, '[]')
                InitialOutput = '0';
            end
            [InitialOutputValue, InitialOutputType, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, InitialOutput);
            if status
                display_msg(sprintf('InitialOutput %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    InitialOutput, blk.Origin_path), ...
                    MsgType.ERROR, 'Outport_To_Lustre', '');
                return;
            end
            if iscell(lus_outputDataType)...
                    && numel(InitialOutputValue) < numel(lus_outputDataType)
                % in the case of bus type, lus_outputDataType is inlined to
                % the basic types of the bus. We need to inline
                % InitialOutputValue as well
                InitialOutputValue = arrayfun(@(x) InitialOutputValue, (1:numel(lus_outputDataType)));
            else
                lus_outputDataType = arrayfun(@(x) {lus_outputDataType}, (1:numel(InitialOutputValue)));
            end
            %
            InitialOutput_cell = cell(1, numel(InitialOutputValue));
            for i=1:numel(InitialOutputValue)
                InitialOutput_cell{i} = SLX2LusUtils.num2LusExp(...
                    InitialOutputValue(i), lus_outputDataType{i}, InitialOutputType);
            end
            if numel(InitialOutput_cell) < max_width
                InitialOutput_cell = arrayfun(@(x) InitialOutput_cell(1), (1:max_width));
            end
            
        end
        
        %% change numerical value to Lustre Expr string based on DataType dt.
        function lustreExp = num2LusExp(v, lus_dt, slx_dt)
            if nargin < 3
                slx_dt = lus_dt;
            end
            if strcmp(lus_dt, 'real')
                lustreExp = RealExpr(v);
            elseif strcmp(lus_dt, 'int')
                if numel(slx_dt) > 3 ...
                        && strncmp(slx_dt, 'int', 3) ...
                        || strncmp(slx_dt, 'uint', 4)
                    % e.g. cast double value to int32
                    f = eval(strcat('@', slx_dt));
                    lustreExp = IntExpr(...
                        f(v));
                else
                    lustreExp = IntExpr(v);
                end
            elseif strcmp(lus_dt, 'bool')
                lustreExp = BooleanExpr(v);
            elseif strncmp(slx_dt, 'int', 3) ...
                    || strncmp(slx_dt, 'uint', 4)
                lustreExp = IntExpr(v);
            elseif strcmp(slx_dt, 'boolean') || strcmp(slx_dt, 'logical')
               lustreExp = BooleanExpr(v);
            else
                lustreExp = RealExpr(v);
            end
        end
        %% Data type conversion node name
        function new_callObj = setArgInConvFormat(callObj, arg)
            % this function goes with dataType_conversion funciton to set 
            % the missing argument in conv_format.
            
            if isempty(callObj)
                new_callObj = arg;
                return;
            end
            new_callObj = callObj.deepCopy();
            args = new_callObj.getArgs();
            if iscell(args) && numel(args) == 1
                new_args = args{1};
            else
                new_args = args;
            end
            if isempty(new_args)
                new_callObj.setArgs(arg);
            elseif isa(new_args, 'NodeCallExpr')
                new_callObj.setArgs(...
                    SLX2LusUtils.setArgInConvFormat(new_args, arg));
            end
        end
        function [external_lib, conv_format] = dataType_conversion(inport_dt, outport_dt, RndMeth, SaturateOnIntegerOverflow)
            lus_in_dt = SLX2LusUtils.get_lustre_dt( inport_dt);
            if nargin < 3 || isempty(RndMeth)
                if strcmp(lus_in_dt, 'int')
                    RndMeth = 'int_to_real';
                else
                    RndMeth = 'real_to_int';
                end
            else
                if strcmp(lus_in_dt, 'int')
                    RndMeth = 'int_to_real';
                    
                elseif strcmp(RndMeth, 'Simplest') || strcmp(RndMeth, 'Zero')
                    RndMeth = 'real_to_int';
                else
                    RndMeth = strcat('_',RndMeth);
                end
            end
            if nargin < 4 || isempty(SaturateOnIntegerOverflow)
                SaturateOnIntegerOverflow = 'off';
            end
            external_lib = {};
            conv_format = {};
            
            switch outport_dt
                case 'boolean'
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {'LustDTLib_int_to_bool'};
                        conv_format = NodeCallExpr('int_to_bool', {});
                    elseif strcmp(lus_in_dt, 'real')
                        external_lib = {'LustDTLib_real_to_bool'};
                        conv_format = NodeCallExpr('real_to_bool', {});
                    end
                case {'double', 'single'}
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {strcat('LustDTLib_', RndMeth)};
                        conv_format = NodeCallExpr(RndMeth, {});
                    elseif strcmp(lus_in_dt, 'bool')
                        external_lib = {'LustDTLib_bool_to_real'};
                        conv_format = NodeCallExpr('bool_to_real', {});
                    end
                case {'int8','uint8','int16','uint16', 'int32','uint32'}
                    if strcmp(SaturateOnIntegerOverflow, 'on')
                        conv = strcat('int_to_', outport_dt, '_saturate');
                    else
                        conv = strcat('int_to_', outport_dt);
                    end
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {strcat('LustDTLib_',conv)};
                        conv_format = NodeCallExpr(conv, {});
                    elseif strcmp(lus_in_dt, 'bool')
                        external_lib = {'LustDTLib_bool_to_int'};
                        conv_format = NodeCallExpr('bool_to_int', {});
                    elseif strcmp(lus_in_dt, 'real')
                        external_lib = {strcat('LustDTLib_', conv),...
                            strcat('LustDTLib_', RndMeth)};
                        conv_format = NodeCallExpr(conv, ...
                            NodeCallExpr(RndMeth, {}));
                    end
                    
                    
                    
                    %lustre conversion
                case 'int'
                    if strcmp(lus_in_dt, 'bool')
                        external_lib = {'LustDTLib_bool_to_int'};
                        conv_format = NodeCallExpr('bool_to_int', {});
                    elseif strcmp(lus_in_dt, 'real')
                        external_lib = {strcat('LustDTLib_', RndMeth)};
                        conv_format = NodeCallExpr(RndMeth, {});
                    end
                case 'real'
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {strcat('LustDTLib_', RndMeth)};
                        conv_format = NodeCallExpr(RndMeth, {});
                    elseif strcmp(lus_in_dt, 'bool')
                        external_lib = {'LustDTLib_bool_to_real'};
                        conv_format = NodeCallExpr('bool_to_real', {});
                    end
                case 'bool'
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {'LustDTLib_int_to_bool'};
                        conv_format = NodeCallExpr('int_to_bool', {});
                    elseif strcmp(lus_in_dt, 'real')
                        external_lib = {'LustDTLib_real_to_bool'};
                        conv_format = NodeCallExpr('real_to_bool', {});
                    end
                    
                otherwise
                    %fixdt 
                    if strcmp(lus_in_dt, 'int')
                        external_lib = {strcat('LustDTLib_', RndMeth)};
                        conv_format = NodeCallExpr(RndMeth, {});
                    elseif strcmp(lus_in_dt, 'bool')
                        external_lib = {'LustDTLib_bool_to_real'};
                        conv_format = NodeCallExpr('bool_to_real', {});
                    end
            end
        end
        
        %% reset conditions
        function isSupported = resetTypeIsSupported(resetType)
            supported = {'rising', 'falling', 'either', 'level', 'level hold'};
            isSupported = ismember(lower(resetType), supported);
        end
        function [resetCode, status] = getResetCode(...
                resetType, resetDT, resetInput, zero )
            status = 0;
            if strcmp(resetDT, 'bool')
                b = resetInput;
            else
                %b = sprintf('(%s > %s)',resetInput , zero);
                b = BinaryExpr(BinaryExpr.GT, resetInput, zero);
            end
            if strcmpi(resetType, 'rising')
                resetCode = ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                               BooleanExpr('false'),...
                               BinaryExpr(BinaryExpr.AND,...
                                          b, ...
                                          UnaryExpr(UnaryExpr.NOT, ...
                                                    UnaryExpr(UnaryExpr.PRE, b)...
                                                    )...
                                         )...
                              );
                          %                 resetCode = sprintf(...
                          %                     'false -> (%s and not pre %s)'...
                          %                     ,b ,b );

            elseif strcmpi(resetType, 'falling')
                %resetCode = sprintf(...
                %    'false -> (not %s and pre %s)'...
                %    ,b ,b);
                resetCode = ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                               BooleanExpr('false'),...
                               BinaryExpr(BinaryExpr.AND,...
                                          UnaryExpr(UnaryExpr.NOT, b), ...
                                          UnaryExpr(UnaryExpr.PRE, b)...
                                         )...
                              );
            elseif strcmpi(resetType, 'either')
                %                 resetCode = sprintf(...
                %                     'false -> ((%s and not pre %s) or (not %s and pre %s)) '...
                %                     ,b ,b ,b ,b);
                resetCode = ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                               BooleanExpr('false'),...
                               BinaryExpr(BinaryExpr.OR,...
                                          BinaryExpr(BinaryExpr.AND,...
                                                      b, ...
                                                      UnaryExpr(UnaryExpr.NOT, ...
                                                                UnaryExpr(UnaryExpr.PRE, b)...
                                                                )...
                                                     ),...
                                          BinaryExpr(BinaryExpr.AND,...
                                                      UnaryExpr(UnaryExpr.NOT, b), ...
                                                      UnaryExpr(UnaryExpr.PRE, b)...
                                                     )...
                                          )...
                              );
            elseif strcmpi(resetType, 'level')

                if strcmp(resetDT, 'bool')
                    b = resetInput;
                else
                    %b = sprintf('(%s <> %s)',resetInput , zero);
                    b = BinaryExpr(BinaryExpr.NEQ, resetInput, zero);
                end
                % Reset in either of these cases:
                % when the reset signal is nonzero at the current time step
                % when the reset signal value changes from nonzero at the previous time step to zero at the current time step
                %                 resetCode = sprintf(...
                %                     'false -> (%s or (pre %s and not %s)) '...
                %                     ,b ,b ,b);
                resetCode = ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                               BooleanExpr('false'),...
                               BinaryExpr(BinaryExpr.OR,...
                                          b,...
                                          BinaryExpr(BinaryExpr.AND,...
                                                    UnaryExpr(UnaryExpr.PRE, b),...
                                                    UnaryExpr(UnaryExpr.NOT, b) ...
                                                    )...
                                          )... 
                              );
            elseif strcmpi(resetType, 'level hold')

                if strcmp(resetDT, 'bool')
                    b = resetInput;
                else
                    %b = sprintf('(%s <> %s)',resetInput , zero);
                    b = BinaryExpr(BinaryExpr.NEQ, resetInput, zero);
                end
                %Reset when the reset signal is nonzero at the current time step
                %                 resetCode = sprintf(...
                %                     'false -> b);
                resetCode = ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                               BooleanExpr('false'),...
                               b);              
                         
            else
                resetCode = VarIdExpr('');
                status = 1;
                return;
            end
        end
        
        
        
        %% Add clocks of RateTransitions
        function time_step = clockName(st_n, ph_n)
            time_step = sprintf('_clk_%.0f_%.0f', st_n, ph_n);
        end
        function b = isIgnoredSampleTime(st_n, ph_n)
            b = (st_n == 1 || st_n == 0 || isinf(st_n) || isnan(st_n))...
                && (ph_n == 0 || isinf(ph_n) || isnan(ph_n));
        end
        function clocks_list = getRTClocksSTR(blk, main_sampleTime)
            clocks_list = {};
            clocks = blk.CompiledSampleTime;
            if iscell(clocks) && numel(clocks) > 1
                clocks_list = {};
                for i=1:numel(clocks)
                    T = clocks{i};
                    if T(1) < 0 || isinf(T(1))
                        continue;
                    end
                    st_n = T(1)/main_sampleTime(1);
                    ph_n = T(2)/main_sampleTime(1);
                    if ~SLX2LusUtils.isIgnoredSampleTime(st_n, ph_n)
                        clocks_list{end+1} = SLX2LusUtils.clockName(st_n, ph_n);
                    end
                end
            end
        end
    end
    
end

