classdef ContractRequireBlock_To_Lustre < nasa_toLustre.blocks.SubSystem_To_Lustre
    % ContractRequireBlock_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin)
            write_code@nasa_toLustre.blocks.SubSystem_To_Lustre(obj, ...
                parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin{:});
            prop_ID =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            xml_trace.add_Property(...
                blk.Origin_path, ...
                nasa_toLustre.utils.SLX2LusUtils.node_name_format(parent),...
                prop_ID, 1, 'require')
        end
        
        function options = getUnsupportedOptions(obj, parent, blk,...
                lus_backend, varargin)
            options = getUnsupportedOptions@nasa_toLustre.blocks.SubSystem_To_Lustre(obj,...
                parent, blk, lus_backend, varargin{:});
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

