classdef Gain_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Gain_To_Lustre: This function support scalar Gain. Matrix/Vector gains
    %are supported by Gain_pp in the pre-processing step.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, varargin)
            global  CoCoSimPreferences;
            %This function support scalar Gain. Matrix/Vector gains
            %are supported by Gain_pp in the pre-processing step.
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport{1};
            lusInDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
            %converts the input data type(s) to
            %its output data type
            if ~strcmp(lusInDT, 'bool') && ~strcmp(inport_dt, outputDataType)
                RndMeth = blk.RndMeth;
                SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
                [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                    inputs{1} = cellfun(@(x) ...
                        nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                        inputs{1}, 'un', 0);
                end
            end
            [lusOutDT, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            
            [gain, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Gain);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Gain, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            if numel(gain) > 1
                display_msg(sprintf('Matrix/Vector Gain "%s" in Gain block "%s" is supported in pre-processing. See pre-processing errors.',...
                    blk.Gain, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            if strcmp(lusOutDT, 'int')
                gainAst = nasa_toLustre.lustreAst.IntExpr(gain);
            elseif strcmp(lusOutDT, 'bool')
                % this case never occur as output can never be bool.
                gainAst = nasa_toLustre.lustreAst.BooleanExpr(gain);
            else
                gainAst = nasa_toLustre.lustreAst.RealExpr(gain);
            end
            codes = cell(1, numel(inputs{1}));
            for j=1:numel(inputs{1})
                if strcmp(lusInDT, 'bool')
                    code = nasa_toLustre.lustreAst.IteExpr(inputs{1}{j}, gainAst, zero);
                else
                    code = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, inputs{1}{j}, gainAst);
                end
                codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, code);
            end
            
            obj.addCode(codes);
            
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            obj.unsupported_options = {};
            [gain, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Gain);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Gain, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            if numel(gain) > 1
                obj.addUnsupported_options(sprintf('Matrix/Vector Gain "%s" in Gain block "%s" should be supported in pre-processing (Gain_pp). See pre-processing errors above.',...
                    blk.Gain, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

