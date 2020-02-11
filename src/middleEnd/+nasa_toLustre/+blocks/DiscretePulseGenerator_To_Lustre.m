%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh <khanh.v.trinh@nasa.gov>
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
classdef DiscretePulseGenerator_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Demux_To_Lustre
    % if (t >= PhaseDelay) && Pulse is on
    %      Y(t) = Amplitude
    % else
    %       Y(t) = 0
    % end

%    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            
            PulseType = blk.PulseType;  % 'Time based' or 'Sample based'
            if strcmp(blk.TimeSource, 'Use external signal')
                display_msg(sprintf('Option "Use external signal" is not supported for block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            [Amplitude, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Amplitude);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Amplitude, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            
            [Period, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Period);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Period, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            
            [PulseWidth, ~, status] = ...               % percent of period
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.PulseWidth);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.PulseWidth, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            
            [PhaseDelay, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.PhaseDelay);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.PhaseDelay, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            % inline all parameters to
            max_width =numel(outputs);
            if numel(Amplitude) < max_width
                Amplitude = arrayfun(@(x) Amplitude(1), (1:max_width));
            end
            if numel(Period) < max_width
                Period = arrayfun(@(x) Period(1), (1:max_width));
            end
            if numel(PulseWidth) < max_width
                PulseWidth = arrayfun(@(x) PulseWidth(1), (1:max_width));
            end
            if numel(PhaseDelay) < max_width
                PhaseDelay = arrayfun(@(x) PhaseDelay(1), (1:max_width));
            end
            
            if strcmp(PulseType, 'Time based')
                % switch PulseWidth to seconds
                PulseWidth = (PulseWidth .* Period)/100.0;
                % normalize parameters
                Period = Period / main_sampleTime(1);
                PulseWidth = PulseWidth / main_sampleTime(1);
                PhaseDelay = PhaseDelay / main_sampleTime(1);
            end
            
            
            
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                if strcmp(outputs_dt{i}.getDT(), 'real')
                    zero = nasa_toLustre.lustreAst.RealExpr('0.0');
                    amp = nasa_toLustre.lustreAst.RealExpr(Amplitude(i));
                elseif strcmp(outputs_dt{i}.getDT(), 'int')
                    zero = nasa_toLustre.lustreAst.IntExpr(0);
                    amp = nasa_toLustre.lustreAst.IntExpr(Amplitude(i));
                else
                    zero = nasa_toLustre.lustreAst.BoolExpr('false');
                    amp = nasa_toLustre.lustreAst.BoolExpr(Amplitude(i));
                end                
                if PhaseDelay(i) == 0
                    cond = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, ...
                                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD, ...
                                   nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr()), ...   
                                   nasa_toLustre.lustreAst.IntExpr(Period(i))), ...
                               nasa_toLustre.lustreAst.IntExpr(PulseWidth(i)));
                else
                    cond = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GTE, ...
                                    nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr()), ...
                                    nasa_toLustre.lustreAst.IntExpr(PhaseDelay(i))), ...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, ...
                                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD, ...
                                              nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS, ...
                                                        nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.utils.SLX2LusUtils.nbStepStr()), ...
                                                        nasa_toLustre.lustreAst.IntExpr(PhaseDelay(i))), ...
                                              nasa_toLustre.lustreAst.IntExpr(Period(i))), ...
                                    nasa_toLustre.lustreAst.IntExpr(PulseWidth(i))));
                end
                codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                    nasa_toLustre.lustreAst.IteExpr(cond, ...
                    amp, ...
                    zero));
               
            end
            
            
            obj.addCode( codes );
            
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, lus_backend, varargin)
            
            if LusBackendType.isJKIND(lus_backend)
                obj.addUnsupported_options(sprintf(...
                    ['Block "%s" is not supported by JKind model checker.', ...
                'This optiont is supported by the other model checkers. ', ...
                cocosim_menu.CoCoSimPreferences.getChangeModelCheckerMsg()], ...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            [~, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Amplitude);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Amplitude, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            [~, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Period);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Period, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            [~, ~, status] = ...              
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.PulseWidth);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.PulseWidth, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            [~, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.PhaseDelay);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.PhaseDelay, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            if strcmp(blk.TimeSource, 'Use external signal')
                obj.addUnsupported_options(sprintf('Option "Use external signal" is not supported for block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

