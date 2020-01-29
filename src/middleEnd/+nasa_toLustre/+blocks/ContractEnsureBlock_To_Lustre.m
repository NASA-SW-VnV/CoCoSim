classdef ContractEnsureBlock_To_Lustre < nasa_toLustre.blocks.SubSystem_To_Lustre
    % ContractEnsureBlock_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin)
            write_code@nasa_toLustre.blocks.SubSystem_To_Lustre(obj, ...
                parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin{:});
        end
        
        function options = getUnsupportedOptions(obj, parent, blk,...
                lus_backend, varargin)
            getUnsupportedOptions@nasa_toLustre.blocks.SubSystem_To_Lustre(obj,...
                parent, blk, lus_backend, varargin{:});
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

