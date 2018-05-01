classdef BusSelector_To_Lustre < Block_To_Lustre
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
        
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk);
            obj.addVariable(outputs_dt);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            codes = {};
            % everything is inlined
            InportDimensions = blk.CompiledPortDimensions.Inport;
            InputSignals = blk.InputSignals;
            OutputSignals = regexp(blk.OutputSignals, ',', 'split');
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
                    inport_cell_dimension = SLX2LusUtils.getDimensionsFromBusObject(InportDT);
                else
                    display_msg(sprintf('Block %s with type %s is not supported.', ...
                        blk.Origin_path,InportDT ),...
                        MsgType.ERROR, 'BusSelector_To_Lustre', '');
                    return;
                end
            end
            [SignalsInputsMap, status] = BusSelector_To_Lustre.signalInputsUsingDimensions(...
                inport_cell_dimension, inputSignalsInlined, inputs);
            if status
                display_msg(sprintf('Block %s is not supported.', blk.Origin_path),...
                    MsgType.ERROR, 'BusSelector_To_Lustre', '');
                return;
            end
            out_idx = 1;
            for i=1:numel(OutputSignals)
                if isKey(SignalsInputsMap, OutputSignals{i})
                    inputs_i = SignalsInputsMap(OutputSignals{i});
                else
                    display_msg(sprintf('Block %s with type %s is not supported.',...
                        blk.Origin_path, OutputSignals{i}),...
                        MsgType.ERROR, 'BusSelector_To_Lustre', '');
                    continue;
                end
                for j=1:numel(inputs_i)
                    codes{end+1} = sprintf('%s = %s;\n\t', outputs{out_idx}, inputs_i{j});
                    out_idx = out_idx + 1;
                end
            end
            
            obj.setCode( MatlabUtils.strjoin(codes, ''));
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            options = obj.unsupported_options;
        end
    end
    
    methods(Static)
        function [SignalsInputsMap, status] = signalInputsUsingDimensions(...
                inport_cell_dimension, inputSignalsInlined, inputs)
            status = 0;
            if numel(inport_cell_dimension) ~= numel(inputSignalsInlined)
                status = 1;
                return;
            end
            SignalsInputsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
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
        
        % this function takes InputSignals parameter and inline it.
        %example
        % InputSignals = {'x4', {'bus2', {{'bus1', {'chirp', 'sine'}}, 'step'}}}
        % inputSignalsInlined = { 'x4', 'bus2.bus1.chirp', 'bus2.bus1.sine', 'bus2.step'}
        function inputSignalsInlined = inlineInputSignals(InputSignals, main_cell, prefix)
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

