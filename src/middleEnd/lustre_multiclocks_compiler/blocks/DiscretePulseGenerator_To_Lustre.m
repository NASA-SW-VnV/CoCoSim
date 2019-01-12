classdef DiscretePulseGenerator_To_Lustre < Block_To_Lustre
    % Demux_To_Lustre
    % if (t >= PhaseDelay) && Pulse is on
    %      Y(t) = Amplitude
    % else
    %       Y(t) = 0
    % end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            
            PulseType = blk.PulseType;  % 'Time based' or 'Sample based'
            if strcmp(blk.TimeSource, 'Use external signal')
                display_msg(sprintf('Option "Use external signal" is not supported for block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            [Amplitude, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Amplitude);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Amplitude, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            
            [Period, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Period);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Period, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            
            [PulseWidth, ~, status] = ...               % percent of period
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.PulseWidth);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.PulseWidth, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            
            [PhaseDelay, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.PhaseDelay);
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
                if isequal(outputs_dt{i}.getDT(), 'real')
                    zero = RealExpr('0.0');
                    amp = RealExpr(Amplitude(i));
                elseif isequal(outputs_dt{i}.getDT(), 'int')
                    zero = IntExpr(0);
                    amp = IntExpr(Amplitude(i));
                else
                    zero = BooleanExpr('false');
                    amp = BooleanExpr(Amplitude(i));
                end                
                if PhaseDelay(i) == 0
                    cond = BinaryExpr(BinaryExpr.LT, ...
                                BinaryExpr(BinaryExpr.MOD, ...
                                   VarIdExpr(SLX2LusUtils.nbStepStr()), ...   
                                   IntExpr(Period(i))), ...
                               IntExpr(PulseWidth(i)));
                else
                    cond = BinaryExpr(BinaryExpr.AND, ...
                        BinaryExpr(BinaryExpr.GTE, ...
                                    VarIdExpr(SLX2LusUtils.nbStepStr()), ...
                                    IntExpr(PhaseDelay(i))), ...
                        BinaryExpr(BinaryExpr.LT, ...
                                    BinaryExpr(BinaryExpr.MOD, ...
                                              BinaryExpr(BinaryExpr.MINUS, ...
                                                        VarIdExpr(SLX2LusUtils.nbStepStr()), ...
                                                        IntExpr(PhaseDelay(i))), ...
                                              IntExpr(Period(i))), ...
                                    IntExpr(PulseWidth(i))));
                end
                codes{i} = LustreEq(outputs{i}, ...
                    IteExpr(cond, ...
                    amp, ...
                    zero));
               
            end
            
            
            obj.setCode( codes );
            
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            [~, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Amplitude);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Amplitude, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            [~, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Period);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Period, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            [~, ~, status] = ...              
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.PulseWidth);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.PulseWidth, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            
            [~, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.PhaseDelay);
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

