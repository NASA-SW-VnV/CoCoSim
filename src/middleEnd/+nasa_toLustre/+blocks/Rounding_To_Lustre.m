classdef Rounding_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % RoundingFunction_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            
            widths = blk.CompiledPortWidths.Inport;
            RndMeth = blk.Operator;
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
            end
            % we use _ before the node name. round => _round
            RndMeth = sprintf('_%s', RndMeth);
            
            obj.addExternal_libraries(strcat('LustDTLib_',RndMeth))
            % Just pass inputs to outputs.
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                codes{i} = LustreEq(outputs{i}, ...
                    NodeCallExpr(RndMeth, inputs{1}{i}));
            end
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(~, lus_backend, varargin)
            is_Abstracted = LusBackendType.isKIND2(lus_backend);
        end
    end
    

    
end

