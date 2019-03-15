classdef FunctionCallSplit_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % FunctionCallSplit_To_Lustre
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
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            inputs =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            
            % pass inputs variables
            codes = arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{1}), ...
                (1:numel(outputs)), 'un', 0);
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
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

