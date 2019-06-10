classdef Width_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Width_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            
            
            codes =  cell(1, numel(outputs));
            
            
            slx_dt = blk.CompiledPortDataTypes.Outport{1};
            lus_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
            width = blk.CompiledPortWidths.Inport(1);
            codes{1} = nasa_toLustre.lustreAst.LustreEq(outputs{1}, ...
                nasa_toLustre.utils.SLX2LusUtils.num2LusExp(width, lus_dt, slx_dt));
            
            obj.addCode( codes );
            
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

