classdef Chart_To_Lustre < Block_To_Lustre
    % Chart_To_Lustre translates Stateflow chart to Lustre.
    % This version is temporal using the old compiler. New version using
    % lustref compiler is comming soon.
    
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
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            % This current version is using old lustre compiler for Stateflow
            node_name = get_full_name( blk, true );
            
            code = LustreEq(outputs, NodeCallExpr(node_name, inputs));

            obj.setCode( code );
            obj.addVariable(outputs_dt); 
        end
        
        function options = getUnsupportedOptions(obj,~, ~, varargin)
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

