classdef Rounding_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % RoundingFunction_To_Lustre

%    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            
            RndMeth = blk.Operator;
            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            % we use _ before the node name. round => _round
            RndMeth = sprintf('_%s', RndMeth);
            
            obj.addExternal_libraries(strcat('LustDTLib_',RndMeth))
            % Just pass inputs to outputs.
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                    nasa_toLustre.lustreAst.NodeCallExpr(RndMeth, inputs{1}{i}));
            end
            
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

