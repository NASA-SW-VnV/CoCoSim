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
classdef Switch_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Switch_To_Lustre

%    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            
            if strcmp(blk.AllowDiffInputSizes, 'on')
                display_msg(sprintf('The Allow different data input sizes option is not support in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'Switch_To_Lustre', '');
            end
            
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            [threshold, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Threshold);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Threshold, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustre', '');
                return;
            end
            secondInputIsBoolean = 0;
            threshold_ast = {};
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType) && i~=2
                    [external_lib, conv_format] = ...
                       nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x), ...
                            inputs{i}, 'un', 0);
                    end
                elseif i==2
                    [lus_inportDataType, ~] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
                    if strcmp(blk.Criteria, 'u2 ~= 0')
                        if strcmp(lus_inportDataType, 'real')
                            threshold_str_temp = nasa_toLustre.lustreAst.RealExpr('0.0');
                        elseif strcmp(lus_inportDataType, 'int')
                            threshold_str_temp = nasa_toLustre.lustreAst.IntExpr(0);
                        else
                            threshold_str_temp = nasa_toLustre.lustreAst.BoolExpr('false');
                            secondInputIsBoolean = 1;
                        end
                        threshold_ast = cell(1, max_width);
                        for j=1:max_width
                            threshold_ast{j} = threshold_str_temp;
                        end
                            
                    else
                        threshold_ast = cell(1, numel(threshold));
                        for j=1:numel(threshold)
                            if strcmp(lus_inportDataType, 'real')
                                threshold_ast{j} = nasa_toLustre.lustreAst.RealExpr(threshold(j));
                            elseif strcmp(lus_inportDataType, 'int')
                                threshold_ast{j} = nasa_toLustre.lustreAst.IntExpr(int32(threshold(j)));
                            else
                                secondInputIsBoolean = 1;
                            end
                        end
                        if numel(threshold) < max_width && ~secondInputIsBoolean
                            threshold_ast = arrayfun(@(x) threshold_ast{1},...
                                (1:max_width), 'UniformOutput', 0);
                        end
                        if numel(inputs{i}) < max_width
                            inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                        end                        %
                    end
                end
            end
            
            
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                if secondInputIsBoolean
                    cond = inputs{2}{i};
                else
                    if strcmp(blk.Criteria, 'u2 > Threshold')
                        cond = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, ...
                            inputs{2}{i}, threshold_ast{i});
                    elseif strcmp(blk.Criteria, 'u2 >= Threshold')
                        cond = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GTE, ...
                            inputs{2}{i}, threshold_ast{i});
                    elseif strcmp(blk.Criteria, 'u2 ~= 0')
                        cond = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.NEQ, ...
                            inputs{2}{i}, threshold_ast{i});
                    end
                end
                codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                    nasa_toLustre.lustreAst.IteExpr(cond, inputs{1}{i}, inputs{3}{i}));
            end
            
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
            
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    lusOutDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
        end
        %%
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            
            if strcmp(blk.AllowDiffInputSizes, 'on')
                obj.addUnsupported_options(...
                    sprintf('The Allow different data input sizes option is not supported in block %s', HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

