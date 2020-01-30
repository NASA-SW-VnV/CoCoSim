classdef SampleTimeMath_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % SampleTimeMath_To_Lustre

%    
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

