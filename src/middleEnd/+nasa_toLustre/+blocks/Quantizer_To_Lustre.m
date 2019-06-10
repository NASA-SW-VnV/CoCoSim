classdef Quantizer_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Quantizer_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(varargin)
           %% Block supported by Pre-Processing
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            obj.unsupported_options = {...
                sprintf('Block %s is supported by Pre-processing check the pre-processing errors.',...
                HtmlItem.addOpenCmd(blk.Origin_path))};
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
end

