classdef FunctionCallGenerator_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % FunctionCallGenerator_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace,~, ~, main_sampleTime, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            
            digitalsampleTime = blk.CompiledSampleTime(1) / main_sampleTime(1);
            codes = arrayfun(@(i) ...
                LustreEq(outputs{i}, ...
                BinaryExpr(BinaryExpr.EQ,...
                BinaryExpr(BinaryExpr.MOD,...
                VarIdExpr(SLX2LusUtils.nbStepStr()),...
                IntExpr(digitalsampleTime)), ...
                IntExpr(0))), ...
                (1:numel(outputs)), 'un', 0);
            obj.setCode( codes );
            
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            [numberOfIterations, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.numberOfIterations);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Value, HtmlItem.addOpenCmd(blk.Origin_path)));
            elseif numberOfIterations ~= 1
                obj.addUnsupported_options(sprintf('Number of iteration %d exceeds 1 in block %s. CoCoSim currently does not support number of iterations > 1. Work on progress!',...
                    numberOfIterations, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    
    
end

