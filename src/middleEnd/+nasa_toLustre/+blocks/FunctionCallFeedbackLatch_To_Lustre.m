classdef FunctionCallFeedbackLatch_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % FunctionCallFeedbackLatch_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
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
            slx_dt = blk.CompiledPortDataTypes.Outport{1};
            lus_outputDataType =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
            inputs =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            Value = 0;
            %inline value
            max_width = blk.CompiledPortWidths.Outport;
            if numel(Value) < max_width
                Value = arrayfun(@(x) Value(1), (1:max_width));
            end
            % out = if t=0 then IC else in;
            codes = arrayfun(@(i) ...
                nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                nasa_toLustre.lustreAst.IteExpr(...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr()), nasa_toLustre.lustreAst.IntExpr(0)), ...
                nasa_toLustre.utils.SLX2LusUtils.num2LusExp(Value(i),lus_outputDataType, slx_dt),...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, inputs{i}))), ...
                (1:numel(outputs)), 'un', 0);
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

