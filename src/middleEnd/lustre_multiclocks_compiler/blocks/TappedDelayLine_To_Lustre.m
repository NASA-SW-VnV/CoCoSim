classdef TappedDelayLine_To_Lustre < Block_To_Lustre
    %TappedDelayLine_To_Lustre
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
            %% Step 1: Get the block outputs names,
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            %% Step 2: add outputs_dt to the list of variables to be declared
            % in the var section of the node.
            obj.addVariable(outputs_dt);
            
            %% Step 3: construct the inputs names,
            
            % save the information of the outport dataType,
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            
            %% Step 4: start filling the definition of each output
            
            % Get Blk parameters
            delayOrder = blk.DelayOrder;
            includeCurrent = blk.includeCurrent;
            if strcmp(includeCurrent, 'on')
                n_vinit = numel(outputs) -1;
            else
                n_vinit = numel(outputs);
            end
            vinit = SLX2LusUtils.getInitialOutput(parent, blk,...
                blk.vinit, outputDataType, n_vinit);
            
            
            codes = {};
            
            if strcmp(delayOrder, 'Oldest')
                % flip names
                outputs = flip(outputs);
            end
            
            if strcmp(includeCurrent, 'on')
                prefix = '';
                vindex = 0;
            else
                prefix = sprintf('%s -> pre ', vinit{1});
                vindex = 1;
            end
            
            for j=1:numel(outputs)
                if j==1
                    codes{j} = sprintf('%s = %s %s;\n\t', ...
                        outputs{j}, prefix, inputs{1}{1});
                else
                    codes{j} = sprintf('%s = %s -> pre %s;\n\t', ...
                        outputs{j}, vinit{vindex}, outputs{j-1});
                end
                vindex = vindex + 1;
            end

            % join the lines and set the block code.
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
    end
    
    
end

