classdef Step_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Step_To_Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            [time, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Time);
            [before, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Before);
            [after, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.After);
            %TODO check if this block can generate vector/matrix output
            obj.addCode( ...
                nasa_toLustre.lustreAst.LustreEq(...
                outputs{1}, ...
                nasa_toLustre.lustreAst.IteExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, ...
                                nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.timeStepStr()), ...
                                nasa_toLustre.lustreAst.RealExpr(time)), ...
                    nasa_toLustre.lustreAst.RealExpr(before), ...
                    nasa_toLustre.lustreAst.RealExpr(after))));
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

