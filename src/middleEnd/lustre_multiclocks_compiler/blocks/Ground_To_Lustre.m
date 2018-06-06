classdef Ground_To_Lustre < Block_To_Lustre
    %Ground_To_Lustre
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
            lus_outputDataType = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport{1});
            
            if strcmp(lus_outputDataType, 'bool')
                v = 'false';
            elseif strcmp(lus_outputDataType, 'int')
                v = '0';
            else
                v = '0.0';
            end
            
            for j=1:numel(outputs)
                codes{j} = sprintf('%s = %s;\n\t', outputs{j}, v);
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            options = obj.unsupported_options;
        end
    end
    
    
    
end

