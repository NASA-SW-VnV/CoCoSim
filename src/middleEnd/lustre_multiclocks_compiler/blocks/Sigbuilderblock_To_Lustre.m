classdef Sigbuilderblock_To_Lustre < Block_To_Lustre
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
            [time,data,~] = signalbuilder(blk.Origin_path);
            if numel(outputs) > 1
                codes = cell(1, numel(outputs));
                for i=1:numel(outputs)
                    codeAst = getSigBuilderCode(obj, time{i}, data{i});
                    codes{i} = LustreEq(outputs{i}, codeAst);
                end
                obj.setCode( codes );
            elseif  numel(outputs) == 1
                codeAst = getSigBuilderCode(obj, time, data);
                obj.setCode( LustreEq(outputs{1}, codeAst) );
            end
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
        
        function codeAst = getSigBuilderCode(obj, time, data)
            codeAst = {};
        end
    end
    
end

