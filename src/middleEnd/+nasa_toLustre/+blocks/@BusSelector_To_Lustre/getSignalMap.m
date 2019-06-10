function [SignalsInputsMap, OutputSignals] = getSignalMap(obj, blk, inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    persistent Signals_Width_Map_Log;
    if isempty(Signals_Width_Map_Log)
        Signals_Width_Map_Log = containers.Map('KeyType', 'char', 'ValueType', 'int32');
    end
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
        elseif strcmp(InportDT, 'double') ...
                || strcmp(InportDT, 'single')...
                || MatlabUtils.startsWith(InportDT, 'int')...
                || MatlabUtils.startsWith(InportDT, 'uint')...
                || strcmp(InportDT, 'boolean')
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
    else
        % TODO: this solution should be improved.
        try
            mdl_name = bdroot(blk.Origin_path);
            for i=1:length(inputSignalsInlined)
                if ~isKey(Signals_Width_Map, inputSignalsInlined{i})
                    if isKey(Signals_Width_Map_Log, fullfile(mdl_name, inputSignalsInlined{i}))
                        % use previously computed value
                        Signals_Width_Map(inputSignalsInlined{i}) = Signals_Width_Map_Log(fullfile(mdl_name, inputSignalsInlined{i}));
                    else
                        l = find_system(mdl_name,'FindAll','on','type','line', 'Name', inputSignalsInlined{i});
                        if ~isempty(l)
                            SrcHandle = get_param(l(1), 'SrcPortHandle');
                            w = SLXUtils.getCompiledParam(SrcHandle, 'CompiledPortWidth');
                            Signals_Width_Map(inputSignalsInlined{i}) = w;
                            % to make name unique to a model use mdl_name as prefix.
                            Signals_Width_Map_Log(fullfile(mdl_name, inputSignalsInlined{i})) = w;
                        end
                    end
                end
            end
        catch
            %ignore if not succeeded
        end
    end
    SignalsInputsMap = nasa_toLustre.blocks.BusSelector_To_Lustre.signalInputsUsingDimensions(...
        blk, inport_cell_dimension, inputSignalsInlined, inputs, Signals_Width_Map);
    
end
