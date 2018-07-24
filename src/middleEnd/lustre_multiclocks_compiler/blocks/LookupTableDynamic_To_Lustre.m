classdef LookupTableDynamic_To_Lustre < Block_To_Lustre
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
        
        function  write_code(obj, parent, blk, xml_trace, ~, backend, varargin)

            isLookupTableDynamic = 1;
            external_lib = '';
            [mainCodes, main_vars, nodeCodes] =  ...
                Lookup_nD_To_Lustre.get_code_to_write(parent, blk, xml_trace, isLookupTableDynamic,backend);
            if ~isempty(external_lib)
                obj.addExternal_libraries(external_lib);
            end
            obj.setCode(mainCodes);
            obj.addVariable(main_vars);
            obj.addExtenal_node(nodeCodes);
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};
            [NumberOfTableDimensions, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfTableDimensions);
            if NumberOfTableDimensions >= 7
                obj.unsupported_options{numel(obj.unsupported_options) + 1} = ...
                    sprintf('More than 7 dimensions is not support in block %s', blk.Origin_path);
            end 
            if ~strcmp(blk.InterpMethod, 'Cubic spline')
                obj.unsupported_options{numel(obj.unsupported_options) + 1} = ...
                    sprintf('Cubic spline interpolation is not support in block %s', blk.Origin_path);
            end            
            options = obj.unsupported_options;
        end
    end        
end

