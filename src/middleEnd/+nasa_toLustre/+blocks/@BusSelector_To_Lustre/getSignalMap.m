function [SignalsInputsMap, OutputSignals] = getSignalMap(obj, blk, inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % everything is inlined
    InportDimensions = blk.CompiledPortDimensions.Inport;
    OutportWidths = blk.CompiledPortWidths.Outport;
    InputSignals = blk.InputSignals;
    OutputSignals = regexp(blk.OutputSignals, ',', 'split');
    
    inputSignalsInlined = nasa_toLustre.blocks.BusSelector_To_Lustre.inlineInputSignals(InputSignals);
    if InportDimensions(1) == -2
        % case of virtual bus
        inport_cell_dimension =...
            nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(InportDimensions);
    else
        InportDT = blk.CompiledPortDataTypes.Inport{1};
        try
            isBus = evalin('base', sprintf('isa(%s, ''Simulink.Bus'')',char(InportDT)));
        catch
            isBus = false;
        end
        if isBus
            % case of bus object
            inport_cell_dimension =nasa_toLustre.utils.SLX2LusUtils.getDimensionsFromBusObject(InportDT);
        elseif isequal(InportDT, 'double') ...
                || isequal(InportDT, 'single')...
                || MatlabUtils.startsWith(InportDT, 'int')...
                || MatlabUtils.startsWith(InportDT, 'uint')...
                || isequal(InportDT, 'boolean')
            inport_cell_dimension =...
                nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(InportDimensions);
        else
            ME = MException('COCOSIM:BusSelector_To_Lustre', ...
                'Block %s with type %s is not supported.', ...
                HtmlItem.addOpenCmd(blk.Origin_path), InportDT);
            throw(ME);
        end
    end
    % fill information about each signal with its width.
    Signals_Width_Map = containers.Map('KeyType', 'char', 'ValueType', 'int32');
    for i=1:length(OutputSignals)
        Signals_Width_Map(OutputSignals{i}) = OutportWidths(i);
    end
    if length(inputSignalsInlined) == length(inport_cell_dimension)
        for i=1:length(inport_cell_dimension)
            if ~isKey(Signals_Width_Map, inputSignalsInlined{i})
                Signals_Width_Map(inputSignalsInlined{i}) = inport_cell_dimension{i}.width;
            end
        end
    end
    SignalsInputsMap = nasa_toLustre.blocks.BusSelector_To_Lustre.signalInputsUsingDimensions(...
        blk, inport_cell_dimension, inputSignalsInlined, inputs, Signals_Width_Map);
    
end
