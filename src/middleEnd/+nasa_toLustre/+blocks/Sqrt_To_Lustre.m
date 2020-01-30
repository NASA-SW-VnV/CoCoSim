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
classdef Sqrt_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Sqrt_To_Lustre:

%    properties
        
    end
    
    methods
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                display_msg(sprintf('The minimum/maximum value is not support in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.WARNING, 'Sqrt_To_Lustre', '');
            end
            if strcmp(blk.AlgorithmType, 'Newton-Raphson')
                msg = sprintf('Option Newton-Raphson is not supported in block %s. Exact method will be used.', ...
                    HtmlItem.addOpenCmd(blk.Origin_path));
                display_msg(msg, MsgType.WARNING, 'Sqrt_To_Lustre', '');
            end

            obj.addExternal_libraries('LustMathLib_lustrec_math');
            
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                [inLusDT] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inLusDT, 'real')
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'real', RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            [outLusDT, zero, one] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            
            codes = cell(1, numel(inputs{1}));
            for j=1:numel(inputs{1})
                if strcmp(blk.Operator, 'sqrt')
                    %code = sprintf('sqrt(%s) ',  inputs{1}{j});
                    code = nasa_toLustre.lustreAst.NodeCallExpr('sqrt', inputs{1}{j});
                elseif strcmp(blk.Operator, 'signedSqrt')
                    %code = sprintf('if %s >= %s then sqrt(%s) else -sqrt(-%s)', inputs{1}{j}, zero, inputs{1}{j}, inputs{1}{j});
                    code = nasa_toLustre.lustreAst.IteExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GTE, inputs{1}{j}, zero),...
                        nasa_toLustre.lustreAst.NodeCallExpr('sqrt', inputs{1}{j}), ...
                        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, ...
                                   nasa_toLustre.lustreAst.NodeCallExpr('sqrt', ...
                                                nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG,...
                                                        inputs{1}{j}))));
                elseif strcmp(blk.Operator, 'rSqrt')
                    %code = sprintf('%s/sqrt(%s) ', one, inputs{1}{j});
                    code =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, ...
                        one, ...
                        nasa_toLustre.lustreAst.NodeCallExpr('sqrt', inputs{1}{j}));
                    code.setOperandsDT('real');
                end
               
                 if ~strcmp(outLusDT, 'real')
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('real', outputDataType);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format, code);
                    end
                end
                codes{j} = nasa_toLustre.lustreAst.LustreEq( outputs{j}, code);
            end
            
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
            
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, outLusDT, xml_trace);
                end
            end
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = true;
        end
       
    end
    
end

