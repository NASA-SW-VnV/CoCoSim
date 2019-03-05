function SignalsInputsMap = signalInputsUsingDimensions(...
        blk, inport_cell_dimension, inputSignalsInlined, inputs, Signals_Width_Map)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %L = nasa_toLustre.ToLustreImport.L;
    %import(L{:})
    SignalsInputsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    if numel(inport_cell_dimension) ~= numel(inputSignalsInlined) ...
            && numel(inport_cell_dimension) ~= 1
        ME = MException('COCOSIM:BusSelector_To_Lustre', ...
            'Block %s is not supported. Inport and Outport Dimensions are not compatible.', HtmlItem.addOpenCmd(blk.Origin_path));
        throw(ME);
    end
    if numel(inport_cell_dimension) == 1
        % the case of Busselector with a vector input instead of
        % a bus
        if inport_cell_dimension{1}.width ~= ...
                sum( cellfun(@(x) x, Signals_Width_Map.values))
           % we can not do mapping between inputs and outpus if all
           % of the inputs are not used.
            ME = MException('COCOSIM:BusSelector_To_Lustre', ...
                'Block %s is not supported. All inputs are not selected.', HtmlItem.addOpenCmd(blk.Origin_path));
            throw(ME);
        end
        inputIdx = 1;
        for i=1:numel(inputSignalsInlined)
            inputSignal = inputSignalsInlined{i};
            if isKey(Signals_Width_Map, inputSignal)
                width = Signals_Width_Map(inputSignal);
                tmp_inputs =  inputs(inputIdx:inputIdx + width - 1);
                if isKey(SignalsInputsMap, inputSignal)
                    SignalsInputsMap(inputSignal) = ...
                        [SignalsInputsMap(inputSignal), ...
                        tmp_inputs];
                else
                    SignalsInputsMap(inputSignal) = ...
                        tmp_inputs;
                end
                inputIdx = inputIdx + width;
            else
                ME = MException('COCOSIM:BusSelector_To_Lustre', ...
                    'Block %s is not supported. Input Signal "%s" was not found.', HtmlItem.addOpenCmd(blk.Origin_path), inputSignal);
                throw(ME);
            end
        end

    else
        inputIdx = 1;
        for i=1:numel(inport_cell_dimension)
            width = inport_cell_dimension{i}.width;
            tmp_inputs =  inputs(inputIdx:inputIdx + width - 1);
            tokens = regexp(inputSignalsInlined{i}, '\.', 'split');
            for j=1:numel(tokens)
                prefix = MatlabUtils.strjoin(tokens(1:j), '.');
                if isKey(SignalsInputsMap, prefix)
                    SignalsInputsMap(prefix) = ...
                        [SignalsInputsMap(prefix), ...
                        tmp_inputs];
                else
                    SignalsInputsMap(prefix) = ...
                        tmp_inputs;
                end
            end
            inputIdx = inputIdx + width;
        end
    end
end

