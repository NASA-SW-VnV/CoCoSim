classdef LookupTableDynamic_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Selector_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        function obj = LookupTableDynamic_To_Lustre()
            obj.ContentNeedToBeTranslated = 0;
        end
        function  write_code(obj, parent, blk, xml_trace, lus_backend, varargin)
            %L = nasa_toLustre.ToLustreImport.L;
            %import(L{:})
            isLookupTableDynamic = 1;
            [mainCode, main_vars, extNode, external_lib] =  ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_code_to_write(parent, blk, xml_trace, isLookupTableDynamic,lus_backend);
            if ~isempty(external_lib)
                obj.addExternal_libraries(external_lib);
            end
             
            obj.addExtenal_node(extNode);            
            obj.setCode(mainCode);
            obj.addVariable(main_vars);
        end

        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end        
end

