classdef Subsystem_To_Lustre < Block_To_Lustre
    %Subsystem_To_Lustre translates a subsystem call to Lustre.
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
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            node_name = SLX2LusUtils.node_name_format(blk);
            x = MatlabUtils.strjoin(inputs, ',\n\t');
            y = MatlabUtils.strjoin(outputs, ',\n\t');
            obj.setCode(sprintf('(%s) = %s(%s);\n\t', y, node_name, x));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
           options = obj.unsupported_options;
        end
    end
    
end

