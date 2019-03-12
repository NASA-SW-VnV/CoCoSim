function [SignalsInputsMap, AssignedSignals] = getSignalMap(obj, blk, inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % everything is inlined
    InportDimensions = blk.CompiledPortDimensions.Inport;
    InputSignals = blk.InputSignals;
    AssignedSignals = regexp(blk.AssignedSignals, ',', 'split');
    inputSignalsInlined = nasa_toLustre.blocks.BusSelector_To_Lustre.inlineInputSignals(InputSignals);
    if InportDimensions(1) == -2
        % case of virtual bus
        inport_cell_dimension =...
            nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(InportDimensions);
        if numel(inport_cell_dimension) > numel(inputSignalsInlined)
            inport_cell_dimension = inport_cell_dimension(1:numel(inputSignalsInlined));
        end
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
        else
            ME = MException('COCOSIM:BusAssignment_To_Lustre', ...
                'Block %s with type %s is not supported.', ...
                HtmlItem.addOpenCmd(blk.Origin_path), InportDT);
            throw(ME);
        end
    end
    SignalsInputsMap = nasa_toLustre.blocks.BusSelector_To_Lustre.signalInputsUsingDimensions(...
        blk, inport_cell_dimension, inputSignalsInlined, inputs{1});
end


