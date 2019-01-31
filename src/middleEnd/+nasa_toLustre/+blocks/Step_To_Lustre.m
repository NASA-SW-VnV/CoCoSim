classdef Step_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Step_To_Lustre.
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
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            [time, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Time);
            [before, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Before);
            [after, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.After);
            %TODO check if this block can generate vector/matrix output
            obj.setCode( ...
                LustreEq(...
                outputs{1}, ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.LT, ...
                                VarIdExpr(SLX2LusUtils.timeStepStr()), ...
                                RealExpr(time)), ...
                    RealExpr(before), ...
                    RealExpr(after))));
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

