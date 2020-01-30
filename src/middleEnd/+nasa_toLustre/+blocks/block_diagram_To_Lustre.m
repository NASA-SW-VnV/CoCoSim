classdef block_diagram_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %block_diagram_To_Lustre Here we add only not supported options in a block diagram

    properties
    end
    
    methods
        
        function  write_code( varargin)
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            
            if nasa_toLustre.blocks.SubSystem_To_Lustre.hasEnablePort(blk) ...
                    || nasa_toLustre.blocks.SubSystem_To_Lustre.hasTriggerPort(blk) ...
                    || nasa_toLustre.blocks.SubSystem_To_Lustre.hasResetPort(blk)
                obj.addUnsupported_options(...
                    sprintf('Block diagram "%s" with Enable/Trigger/Reset port in root level is not supported.', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    
end

