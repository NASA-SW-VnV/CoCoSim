classdef BusSelector_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %BusSelector_To_Lustre This block accepts a bus as input which can be
    %created from a Bus Creator, Bus Selector or a block that defines
    %its output using a bus object.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
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
                    codes{out_idx} = nasa_toLustre.lustreAst.LustreEq(outputs{out_idx}, inputs_i{j});
                    out_idx = out_idx + 1;
                end
            end
            
            obj.addCode( codes );
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
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
        [SignalsInputsMap, OutputSignals] = getSignalMap(obj, blk, inputs)

    end
    
    methods(Static)
        SignalsInputsMap = signalInputsUsingDimensions(...
                blk, inport_cell_dimension, inputSignalsInlined, inputs, OutputSignals_Width_Map)
        
        % this function takes InputSignals parameter and inline it.
        %example
        % InputSignals = {'x4', {'bus2', {{'bus1', {'chirp', 'sine'}}, 'step'}}}
        % inputSignalsInlined = { 'x4', 'bus2.bus1.chirp', 'bus2.bus1.sine', 'bus2.step'}
        inputSignalsInlined = inlineInputSignals(InputSignals, main_cell, prefix)

    end
    
    
end

