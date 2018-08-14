classdef Rounding_To_Lustre < Block_To_Lustre
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
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            
            widths = blk.CompiledPortWidths.Inport;
            RndMeth = blk.Operator;
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
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
            obj.unsupported_options = {};
            options = obj.unsupported_options;
        end
    end
    

    
end

