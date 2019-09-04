classdef DiscretePulseGenerator_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Demux_To_Lustre
    % if (t >= PhaseDelay) && Pulse is on
    %      Y(t) = Amplitude
    % else
    %       Y(t) = 0
    % end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
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

