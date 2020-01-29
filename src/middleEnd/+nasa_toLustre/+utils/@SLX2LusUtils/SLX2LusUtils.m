classdef SLX2LusUtils 
    %LUS2UTILS contains all functions that helps in the translation from
    %Simulink to Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    properties
    end
    
    methods (Static = true)
        %% refactoring names
        isEnabled = isEnabledStr()
        isEnabled = isTriggeredStr()
        time_step = timeStepStr()
        time_step = nbStepStr()
        it = iterationVariable()
        res = isContractBlk(ss_ir)
        [lus_path, mat_file, plu_path] = getLusOutputPath(output_dir, model_name, lus_backend)
        %% adapt blocks names to be a valid lustre names.
        str_out = name_format(str)
        
        %% Lustre node name from a simulink block name. Here we choose only
        %the name of the block concatenated to its handle to be unique
        %name.
        node_name = node_name_format(subsys_struct)
        %% Lustre node inputs, outputs
        [node_name,  node_inputs_cell, node_outputs_cell,...
                node_inputs_withoutDT_cell, node_outputs_withoutDT_cell ] = ...
                extractNodeHeader(parent_ir, blk, is_main_node, ...
                isEnableORAction, isEnableAndTrigger, isContractBlk, isMatlabFunction, ...
                main_sampleTime, xml_trace)
        [names, names_withNoDT] = extract_node_InOutputs_withDT(subsys, type, xml_trace, main_sampleTime)

        [node_inputs_cell, node_inputs_withoutDT_cell] = ...
                getTimeClocksInputs(blk, main_sampleTime, node_inputs_cell, node_inputs_withoutDT_cell)

        %% Contract header
        [node_inputs, node_outputs, ...
                    node_inputs_withoutDT, node_outputs_withoutDT ] = ...
                    extractContractHeader(parent_ir, contract, main_sampleTime, xml_trace)

        %% get If the "blk" is the one abstracted by "contract"
        % to use is, blk and contract are objects
        res = isAbstractedByContract(blk, contract)
        %% get block outputs names: inlining dimension
        [names, names_dt] = getBlockOutputsNames(parent, blk, ...
                srcPort, xml_trace, main_sampleTime)
   
    	[names, names_dt] = blockOutputs(portNumber)
                %

        [lus_dt] = SignalHierarchyLusDT(blk, SignalHierarchy)

        %% get block inputs names. E.g subsystem taking input signals from differents blocks.
        % We need to go over all linked blocks and get their output names
        % in the corresponding port number.
        % Read PortConnectivity documentation for more information.
        [inputs, inputs_var] = getBlockInputsNames(parent, blk, Port)

        [inputs] = getSubsystemEnableInputsNames(parent, blk)

        [inputs] = getSubsystemTriggerInputsNames(parent, blk)

        [inputs] = getSubsystemResetInputsNames(parent, blk)

        [inputs] = getSpecialInputsNames(parent, blk, type)

        %% get pre block for specific port number
        [src, srcPort] = getpreBlock(parent, blk, Port)

        %% get pre block DataType for specific port,
        %it is used in the case of 'auto' type.
        lus_dt = getpreBlockLusDT(parent, blk, portNumber)

        lus_dt = getBusCreatorLusDT(parent, srcBlk, portNumber)

        %% Change Simulink DataTypes to Lustre DataTypes. Initial default
        %value is also given as a string.
        [ Lustre_type, zero, one, isBus, isEnum, hasEnum] = ...
                get_lustre_dt( slx_dt)

        %% Bus signal Lustre dataType
        lustreTypes = getLustreTypesFromBusObject(busName)
        
        in_matrix_dimension = getDimensionsFromBusObject(busName)

        
        %% Get the initial ouput of Outport depending on the dimension.
        % the returns a list of LustreExp objects: IntExpr,
        % RealExpr or BooleanExpr
        InitialOutput_cell = getInitialOutput(parent, blk, InitialOutput, slx_dt, max_width)
        
        %% change numerical value to Lustre Expr string based on DataType dt.
        lustreExp = num2LusExp(v, lus_dt, slx_dt)

        %% Data type conversion node name
        new_callObj = setArgInConvFormat(callObj, arg)

        [external_lib, conv_format] = dataType_conversion(inport_dt, outport_dt, RndMeth, SaturateOnIntegerOverflow)

        %% reset conditions
        isSupported = resetTypeIsSupported(resetType)

        [resetCode, status] = getResetCode(resetType, resetDT, resetInput, zero )
        
        %% trigger conditions
        [resetCode, status] = getTriggerCond(triggerType, triggerDT, triggerInput, zero )
        
        %% Add clocks of RateTransitions
        time_step = clockName(st_n, ph_n)

        b = isIgnoredSampleTime(st_n, ph_n)

        clocks_list = getRTClocksSTR(blk, main_sampleTime)
        
        [st, ph] = getSSSampleTime(Clocks, main_sampleTime)
        %% check model compatibility: Variable size signals, Fixed Data types, 
        % main_sample time. ...
        htmlItemMsg = modelCompatibilityCheck(model_name, main_sampleTime)
        
        
    end
    
end

