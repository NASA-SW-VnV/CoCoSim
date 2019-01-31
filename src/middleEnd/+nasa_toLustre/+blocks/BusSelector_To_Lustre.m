classdef BusSelector_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %BusSelector_To_Lustre This block accepts a bus as input which can be
    %created from a Bus Creator, Bus Selector or a block that defines
    %its output using a bus object.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            try
                [SignalsInputsMap, OutputSignals] = obj.getSignalMap( blk, inputs);
            catch me
                if strcmp(me.identifier, 'COCOSIM:BusSelector_To_Lustre')
                    display_msg(me.message, MsgType.ERROR, 'BusSelector_To_Lustre', '');
                    return;
                end
            end
            out_idx = 1;
            codes = cell(1, numel(outputs));
            for i=1:numel(OutputSignals)
                if isKey(SignalsInputsMap, OutputSignals{i})
                    inputs_i = SignalsInputsMap(OutputSignals{i});
                else
                    display_msg(sprintf('Block %s with output signal %s is not supported.',...
                        blk.Origin_path, OutputSignals{i}),...
                        MsgType.ERROR, 'BusSelector_To_Lustre', '');
                    continue;
                end
                for j=1:numel(inputs_i)
                    codes{out_idx} = LustreEq(outputs{out_idx}, inputs_i{j});
                    out_idx = out_idx + 1;
                end
            end
            
            obj.setCode( codes );
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            try
                [SignalsInputsMap, OutputSignals] = obj.getSignalMap( blk, inputs);
                for i=1:numel(OutputSignals)
                    if ~isKey(SignalsInputsMap, OutputSignals{i})
                        obj.addUnsupported_options(sprintf('Block %s with output signal %s is not supported.',...
                            blk.Origin_path, OutputSignals{i}));
                    end
                end
            catch me
                if strcmp(me.identifier, 'COCOSIM:BusSelector_To_Lustre')
                    obj.addUnsupported_options(me.message);
                end
            end
            
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        %%
        function [SignalsInputsMap, OutputSignals] = getSignalMap(obj, blk, inputs)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            % everything is inlined
            InportDimensions = blk.CompiledPortDimensions.Inport;
            OutportWidths = blk.CompiledPortWidths.Outport;
            InputSignals = blk.InputSignals;
            OutputSignals = regexp(blk.OutputSignals, ',', 'split');
            OutputSignals_Width_Map = containers.Map('KeyType', 'char', 'ValueType', 'int32');
            for i=1:numel(OutputSignals)
                OutputSignals_Width_Map(OutputSignals{i}) = OutportWidths(i);
            end
            inputSignalsInlined = BusSelector_To_Lustre.inlineInputSignals(InputSignals);
            if InportDimensions(1) == -2
                % case of virtual bus
                inport_cell_dimension =...
                    Assignment_To_Lustre.getInputMatrixDimensions(InportDimensions);
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
                        Assignment_To_Lustre.getInputMatrixDimensions(InportDimensions);
                else
                    ME = MException('COCOSIM:BusSelector_To_Lustre', ...
                        'Block %s with type %s is not supported.', ...
                        HtmlItem.addOpenCmd(blk.Origin_path), InportDT);
                    throw(ME);
                end
            end
            SignalsInputsMap = BusSelector_To_Lustre.signalInputsUsingDimensions(...
                blk, inport_cell_dimension, inputSignalsInlined, inputs, OutputSignals_Width_Map);
            
        end
    end
    
    methods(Static)
        function SignalsInputsMap = signalInputsUsingDimensions(...
                blk, inport_cell_dimension, inputSignalsInlined, inputs, OutputSignals_Width_Map)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
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
                        sum( cellfun(@(x) x, OutputSignals_Width_Map.values))
                   % we can not do mapping between inputs and outpus if all
                   % of the inputs are used.
                    ME = MException('COCOSIM:BusSelector_To_Lustre', ...
                        'Block %s is not supported. All inputs are selected.', HtmlItem.addOpenCmd(blk.Origin_path));
                    throw(ME);
                end
                inputIdx = 1;
                for i=1:numel(inputSignalsInlined)
                    inputSignal = inputSignalsInlined{i};
                    if isKey(OutputSignals_Width_Map, inputSignal)
                        width = OutputSignals_Width_Map(inputSignal);
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
        
        % this function takes InputSignals parameter and inline it.
        %example
        % InputSignals = {'x4', {'bus2', {{'bus1', {'chirp', 'sine'}}, 'step'}}}
        % inputSignalsInlined = { 'x4', 'bus2.bus1.chirp', 'bus2.bus1.sine', 'bus2.step'}
        function inputSignalsInlined = inlineInputSignals(InputSignals, main_cell, prefix)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            if nargin < 2
                main_cell = 1;
            end
            if nargin < 3
                prefix = '';
            end
            inputSignalsInlined = {};
            if ~main_cell ...
                    && numel(InputSignals) == 2 ...
                    && ischar(InputSignals{1}) ...
                    && iscell(InputSignals{2})
                % the case of nested type
                if isempty(prefix)
                    prefix = InputSignals{1};
                else
                    prefix = sprintf('%s.%s', prefix, InputSignals{1});
                end
                inputSignalsInlined = ...
                    BusSelector_To_Lustre.inlineInputSignals(InputSignals{2}, 0, prefix);
            else
                for i=1:numel(InputSignals)
                    if iscell(InputSignals{i})
                        inputSignalsInlined = [inputSignalsInlined, ...
                            BusSelector_To_Lustre.inlineInputSignals(InputSignals{i}, 0, prefix)];
                    else
                        if isempty(prefix)
                            inputSignalsInlined{end+1} = InputSignals{i};
                        else
                            inputSignalsInlined{end+1} = sprintf('%s.%s', prefix, InputSignals{i});
                        end
                    end
                end
            end
        end
    end
    
    
end

