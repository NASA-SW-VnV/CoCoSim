classdef Assertion_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Assertion_To_Lustre translates the Assertion
    % block from SLDV library.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        function  write_code(obj, parent, blk, xml_trace, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            if isfield(blk, 'Enabled') && isequal(blk.Enabled, 'off')
                return;
            end
            inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport{1};
            inport_lus_dt = SLX2LusUtils.get_lustre_dt(inport_dt);
            
            if ~strcmp(inport_lus_dt, 'bool')
                [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_lus_dt, 'bool');
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                    inputs{1} = cellfun(@(x) ...
                        SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                        inputs{1}, 'un', 0);
                end
            end
            blk_name = SLX2LusUtils.node_name_format(blk);
            parent_name = SLX2LusUtils.node_name_format(parent);
            obj.addCode(LocalPropertyExpr( blk_name, ...
                BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, inputs{1})));
            xml_trace.add_Property(blk.Origin_path, parent_name, blk_name, 1, ...
                'localProperty')
        end
        %%
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    
end

