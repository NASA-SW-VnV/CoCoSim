classdef EnablePort_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %EnablePort is supported by SubSystem_To_Lustre. Here we add only not
    %supported options    

    properties
    end
    
    methods
        
        function  write_code(varargin)
            %already handled by sybsystem2node
        end
        %%
        function options = getUnsupportedOptions(obj, ~, blk, lus_backend, varargin)
            if LusBackendType.isJKIND(lus_backend) ...
                    && strcmp(blk.StatesWhenEnabling, 'reset')
                obj.addUnsupported_options(sprintf(...
                    ['Block "%s" is not supported by JKind model checker.', ...
                ' The block has a "reset" option when the Subsystem is reactivated. ', ...
                'This optiont is supported by the other model checks. ', ...
                cocosim_menu.CoCoSimPreferences.getChangeModelCheckerMsg()], ...
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

