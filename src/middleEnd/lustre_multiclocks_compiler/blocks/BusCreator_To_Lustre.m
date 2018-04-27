classdef BusCreator_To_Lustre < Block_To_Lustre
    %BusCreator_To_Lustre translates the BusCreator block.
    %We inline signals, so Bus creator is just passing the input signals,
    %if there is a Bus object, it is inlined as well. The generated Lustre
    %code will be without records or Bus types.
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
            obj.addVariable(outputs_dt);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            codes = {};
            % everything is inlined
            for i=1:numel(outputs)
                codes{i} = sprintf('%s = %s;\n\t', outputs{i}, inputs{i});
            end
            
            obj.setCode( MatlabUtils.strjoin(codes, ''));
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            options = obj.unsupported_options;
        end
    end
    
end

