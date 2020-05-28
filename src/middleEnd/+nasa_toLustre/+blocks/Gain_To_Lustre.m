%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Gain_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Gain_To_Lustre: This function support scalar Gain. Matrix/Vector gains
    %are supported by Gain_pp in the pre-processing step.

    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            %This function support scalar Gain. Matrix/Vector gains
            %are supported by Gain_pp in the pre-processing step.
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport{1};
            lusInDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
            %converts the input data type(s) to
            %its output data type
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            if ~strcmp(lusInDT, 'bool') && ~strcmp(inport_dt, outputDataType)
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
                gainAst = nasa_toLustre.lustreAst.BoolExpr(gain);
            else
                gainAst = nasa_toLustre.lustreAst.RealExpr(gain);
            end
            
            % if output in "int": add final result conversion to intXX
            if strcmp(lusOutDT, 'int')
                [external_lib, to_intxx_conv_format] = ...
                    nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                    'int', outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(to_intxx_conv_format)
                    obj.addExternal_libraries(external_lib);
                end
            else
                to_intxx_conv_format = {};
            end
            
            codes = cell(1, numel(inputs{1}));
            for j=1:numel(inputs{1})
                if strcmp(lusInDT, 'bool')
                    code = nasa_toLustre.lustreAst.IteExpr(inputs{1}{j}, gainAst, zero);
                else
                    code = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, inputs{1}{j}, gainAst);
                    code.setOperandsDT(lusOutDT);
                end
                if ~isempty(to_intxx_conv_format)
                    code = nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(to_intxx_conv_format,code);
                end
                codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, code);
            end
            
            obj.addCode(codes);
            
            %% Design Error Detection Backend code:
            if coco_nasa_utils.CoCoBackendType.isDED(coco_backend)
                if ismember(coco_nasa_utils.CoCoBackendType.DED_OUTMINMAX, ...
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

