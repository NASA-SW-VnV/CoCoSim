classdef ContractBlock_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % ContractBlock_To_Lustre translates contract observer as contract in
    % kind2
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(varargin)
            % Contracts Subsystems willl be ignored as they will be
            % imported in the node definition of the associate Simulink
            % Subsystem.
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            % add your unsuported options list here
            associatedBlkHandle = blk.AssociatedBlkHandle;
            associatedBlk = get_struct(parent, associatedBlkHandle);
            if ~(isempty(associatedBlk.CompiledPortWidths.Enable) ...
                    && isempty(associatedBlk.CompiledPortWidths.Ifaction)...
                    && isempty(associatedBlk.CompiledPortWidths.Reset)...
                    && isempty(associatedBlk.CompiledPortWidths.Trigger))
                format = 'Contract "%s" can not be associated with "%s" which is Conditionally Executed Subsystem.\n';
                format = [format, ...
                    'Please Create a Subsystem from the block and linked it again to the contract.'];
                obj.addUnsupported_options(...
                    sprintf(format, HtmlItem.addOpenCmd(blk.Origin_path), HtmlItem.addOpenCmd(associatedBlk.Origin_path)));
            end
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

