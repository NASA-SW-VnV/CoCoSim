classdef Outport_To_Lustre < Block_To_Lustre
    %Outport_To_Lustre translates the Outport block
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
            [outputs, ~] = SLX2LusUtils.getBlockOutputsNames(parent, blk);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            isInsideContract = SLX2LusUtils.isContractBlk(parent);
            if isInsideContract
                % ignore output "valid" in contract
                return;
            end
            %% the case of non connected outport block.
            if isempty(inputs)
                if isempty(blk.CompiledPortDataTypes)
                    lus_outputDataType = 'real';
                else
                    lus_outputDataType = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{1});
                end
                zero = SLX2LusUtils.num2LusExp(...
                    0, lus_outputDataType);
                inputs = arrayfun(@(x) {zero}, (1:numel(outputs)));
            end
            %% 
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                %codes{i} = sprintf('%s = %s;\n\t', outputs{i}, inputs{i});
                codes{i} = LustreEq(outputs{i}, inputs{i});
            end
            
            obj.setCode( codes);
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
    end
    
end

