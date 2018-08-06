classdef Clock_To_Lustre < Block_To_Lustre
    %Clock translates the Clock block.
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
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            code = LustreEq( outputs{1},...
                VarIdExpr(SLX2LusUtils.timeStepStr()));
            obj.setCode( code);
        end
        
        function options = getUnsupportedOptions(obj,  varargin)
            options = obj.unsupported_options;
        end
    end
    
end

