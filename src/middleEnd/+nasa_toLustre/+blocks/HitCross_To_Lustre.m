classdef HitCross_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %HitCross_To_Lustre translates the Hit Crossing block.
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
            
            if strcmp(blk.ShowOutputPort, 'off')
                return;
            end
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            out_lus_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            obj.addVariable(outputs_dt);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            
            [HitCrossingOffset, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent,...
                blk, blk.HitCrossingOffset);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.HitCrossingOffset, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustre', '');
                return;
            end
            HitCrossingDirection = blk.HitCrossingDirection;
            slx_inport_dt = blk.CompiledPortDataTypes.Inport(1);
            [lus_inport_dt] = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_inport_dt);
            offset = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(HitCrossingOffset, ...
                lus_inport_dt, slx_inport_dt);
            
            
            % create variable for crossing detection
            % out_CrossCond = (either|rising|falling)(in);
            crossingCond = arrayfun(@(i) ...
                nasa_toLustre.utils.SLX2LusUtils.getResetCode(HitCrossingDirection, lus_inport_dt, inputs{i}, offset ), ...
                (1:numel(outputs)), 'UniformOutput', 0);
            crossingCondVars = cellfun(@(x) ...
                nasa_toLustre.lustreAst.VarIdExpr(strcat(x.getId(), '_CrossCond')), outputs, 'un', 0);
            obj.addVariable(cellfun(@(x) ...
                nasa_toLustre.lustreAst.LustreVar(x.getId(), 'bool'), crossingCondVars, 'un', 0));
            obj.addCode(arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(crossingCondVars{i}, crossingCond{i}), ...
                (1:numel(crossingCondVars)), 'UniformOutput', 0));
            
            % create rhs as independant variable as the output may not be bool
            if strcmp(out_lus_dt, 'bool')
                rhsVars = outputs;
            else
                rhsVars = cellfun(@(x) ...
                    nasa_toLustre.lustreAst.VarIdExpr(strcat(x.getId(), '_value')), outputs, 'un', 0);
                obj.addVariable(cellfun(@(x) ...
                    nasa_toLustre.lustreAst.LustreVar(x.getId(), 'bool'), rhsVars, 'un', 0));
            end
            pre_rhsVars = cellfun(@(x) ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                nasa_toLustre.lustreAst.BoolExpr(false), ...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, x)), rhsVars, 'un', 0);
            rhsValues = arrayfun(@(i) ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.OR, ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, inputs{i}, offset), ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, pre_rhsVars{i}), ...
                crossingCondVars{i})), ...
                (1:numel(rhsVars)), 'UniformOutput', 0);
            obj.addCode(arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(rhsVars{i}, rhsValues{i}), ...
                (1:numel(rhsVars)), 'UniformOutput', 0));
            
            % convert bool to output data type
            if ~strcmp(out_lus_dt, 'bool')
                [external_lib, conv_format] = ...
                    nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('bool', outputDataType);
                if ~isempty(conv_format)
                    rhs = rhsVars;
                    obj.addExternal_libraries(external_lib);
                    rhs = cellfun(@(x) ...
                        nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                        rhs, 'un', 0);
                    codes = arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(outputs{i}, rhs{i}), ...
                        (1:numel(outputs)), 'UniformOutput', 0);
                    obj.addCode( codes );
                end
            end
            
        end
        %%
        function options = getUnsupportedOptions(varargin)
            options = {};
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

