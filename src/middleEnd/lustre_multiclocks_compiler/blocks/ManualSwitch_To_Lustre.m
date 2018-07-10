classdef ManualSwitch_To_Lustre < Block_To_Lustre
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
            isInsideContract = SLX2LusUtils.isContractBlk(parent);
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            if ~isInsideContract, obj.addVariable(outputs_dt);end

            
            inputs = {};
            % take the list of the inputs width
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            % save the information of the outport dataType
            for i=1:numel(widths)
                % fill the names of the ith input.
                % inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
                % and inputs{2} = {'In2_1'}
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
            end
            
            codes = {};
            try
                % check to what input is linked to
                %sw does not exist in IR
                sw = get_param(blk.Origin_path, 'sw');
                if strcmp(sw, '1')
                    port = 1;
                else
                    port = 2;
                end
            catch
                port = 1;
            end
            % Go over outputs
            for j=1:numel(outputs)
                % example of lement wise product block.
                if isInsideContract
                    codes{j} = sprintf('var %s = %s;\n\t', ...
                        strrep(outputs_dt{j}, ';', ''), ...
                        inputs{port}{j});
                else
                    codes{j} = sprintf('%s = %s;\n\t', ...
                        outputs{j}, inputs{port}{j});
                end
                
            end
            % join the lines and set the block code.
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            %             if isequal(blk.varsize, 'on')
            %                 obj.addUnsupported_options(...
            %                     sprintf('Option input signals with different sizes in Block "%s" is not supported.',...
            %                     blk.Origin_path));
            %             end
            options = obj.unsupported_options;
            
        end
    end
    
end

