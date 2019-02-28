classdef ManualSwitch_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % ManualSwitch_To_Lustre translates ManualSwitch by passing the active
    % signal.
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
            
            
            
            % take the list of the inputs width
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            % save the information of the outport dataType
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                % fill the names of the ith input.
                % inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
                % and inputs{2} = {'In2_1'}
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
            end
            
            
            try
                % check to what input is linked to
                %sw does not exist in IR
                if isfield(blk, 'sw')
                    sw = blk.sw;
                else
                    sw = '1';
                end
                if strcmp(sw, '1')
                    port = 1;
                else
                    port = 2;
                end
            catch
                port = 1;
            end
            % Go over outputs
            codes = cell(1, numel(outputs));
            for j=1:numel(outputs)
                codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, inputs{port}{j});
            end
            % join the lines and set the block code.
            obj.setCode( codes );
            
        end
        %%
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

