classdef Step_To_Lustre < Block_To_Lustre
    %Step_To_Lustre.
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
            [time, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Time);
            [before, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Before);
            [after, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.After);
            
            code = sprintf('%s = if %s < %.5f then %.15f else %.15f;\n\t', ...
                outputs{1}, SLX2LusUtils.timeStepStr(), time, before, after);
            obj.setCode( code);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            options = obj.unsupported_options;
        end
    end
    
end

