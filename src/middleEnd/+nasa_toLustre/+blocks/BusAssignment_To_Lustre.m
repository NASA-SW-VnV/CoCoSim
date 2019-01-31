classdef BusAssignment_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %BusAssignment_To_Lustre
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
            widths = blk.CompiledPortWidths.Inport;
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
            end
            try
                [SignalsInputsMap, AssignedSignals] = obj.getSignalMap(blk, inputs);
            catch me
                if strcmp(me.identifier, 'COCOSIM:BusSelector_To_Lustre') ...
                        || strcmp(me.identifier, 'COCOSIM:BusAssignment_To_Lustre')
                    display_msg(me.message, MsgType.ERROR, 'BusAssignment_To_Lustre', '');
                    return;
                end
            end
            modifiedInputs = inputs{1};
            for i=1:numel(AssignedSignals)
                if isKey(SignalsInputsMap, AssignedSignals{i})
                    inputs_i = SignalsInputsMap(AssignedSignals{i});
                else
                    display_msg(sprintf('Block %s with type %s is not supported.',...
                        HtmlItem.addOpenCmd(blk.Origin_path), AssignedSignals{i}),...
                        MsgType.ERROR, 'BusAssignment_To_Lustre', '');
                    continue;
                end
                for j=1:numel(inputs_i)
                    idx = BusAssignment_To_Lustre.findIdx(modifiedInputs, inputs_i{j});
                    modifiedInputs{idx} = ...
                        inputs{i+1}{j};
                end
            end
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                codes{i} = LustreEq(outputs{i}, modifiedInputs{i});
            end
            obj.setCode( codes );
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            widths = blk.CompiledPortWidths.Inport;
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
            end
            try
                [SignalsInputsMap, AssignedSignals] = obj.getSignalMap(blk, inputs);
                for i=1:numel(AssignedSignals)
                    if ~isKey(SignalsInputsMap, AssignedSignals{i})
                        obj.addUnsupported_options(sprintf('Block %s with type %s is not supported.',...
                            HtmlItem.addOpenCmd(blk.Origin_path), AssignedSignals{i}));
                    end
                end
            catch me
                if strcmp(me.identifier, 'COCOSIM:BusSelector_To_Lustre') ...
                        || strcmp(me.identifier, 'COCOSIM:BusAssignment_To_Lustre')
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
        function [SignalsInputsMap, AssignedSignals] = getSignalMap(obj, blk, inputs)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            % everything is inlined
            InportDimensions = blk.CompiledPortDimensions.Inport;
            InputSignals = blk.InputSignals;
            AssignedSignals = regexp(blk.AssignedSignals, ',', 'split');
            inputSignalsInlined = BusSelector_To_Lustre.inlineInputSignals(InputSignals);
            if InportDimensions(1) == -2
                % case of virtual bus
                inport_cell_dimension =...
                    Assignment_To_Lustre.getInputMatrixDimensions(InportDimensions);
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
            SignalsInputsMap = BusSelector_To_Lustre.signalInputsUsingDimensions(...
                blk, inport_cell_dimension, inputSignalsInlined, inputs{1});
        end
    end
    
    methods(Static)
        function idx = findIdx(VarIds, var)
            varNames = cellfun(@(x) x.getId(), VarIds, 'UniformOutput', 0);
            varName = var.getId();
            idx = strcmp(varNames, varName);
        end
    end
    
end

