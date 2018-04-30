classdef Goto_To_Lustre < Block_To_Lustre
    % Goto_To_Lustre: The Goto block passes its input to its corresponding From blocks.
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
            widths = blk.CompiledPortWidths.Inport;
            inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            codes = {};
            for i=1:numel(outputs)
                    codes{i} = sprintf('%s = %s;',outputs{i}, inputs{1}{i});
            end
            obj.setCode(MatlabUtils.strjoin(codes, '\n\t'));
            obj.addVariable(outputs_dt);
            
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
    end
    
end

