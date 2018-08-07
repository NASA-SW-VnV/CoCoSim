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
        
        function  write_code(obj, parent, blk, xml_trace, main_sampleTime, varargin)
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            
            PulseType = blk.PulseType;  % 'Time based' or 'Sample based'
            if strcmp(blk.TimeSource, 'Use external signal')
                display_msg(sprintf('Option "Use external signal" is not supported for block %s',...
                    blk.Origin_path), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            [Amplitude, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Amplitude);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Amplitude, blk.Origin_path), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            
            [Period, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Period);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Period, blk.Origin_path), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            
            [PulseWidth, ~, status] = ...               % percent of period
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.PulseWidth);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.PulseWidth, blk.Origin_path), ...
                    MsgType.ERROR, 'DiscretePulseGenerator_To_Lustre', '');
                return;
            end
            
            [PhaseDelay, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.PhaseDelay);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.PhaseDelay, blk.Origin_path), ...
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
            PulseWidth = (PulseWidth .* Period)/100.0;
            if strcmp(PulseType, 'Time based')
                % adapt parameters
                Period = Period / main_sampleTime(1);
                PulseWidth = PulseWidth / main_sampleTime(1);
                PhaseDelay = PhaseDelay / main_sampleTime(1);
            end
            
            %displayString = sprintf('period: %f, width: %f, phase: %f ',...
            %Period, PulseWidth, PhaseDelay);
            %disp(displayString);
            
            
            blk_name = SLX2LusUtils.node_name_format(blk);
            
            codes = {};
            for i=1:numel(outputs)
                dtc = VarIdExpr(sprintf('counter_%s_%d', blk_name, i));
                obj.addVariable(LustreVar( dtc, 'int'));
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
                %output = if dtc < PulseWidth and dtc >= 0
                %     then PulseAmp else 0.0;
                cond = BinaryExpr(BinaryExpr.AND, ...
                    BinaryExpr(BinaryExpr.LT, ...
                    dtc, ...
                    IntExpr(PulseWidth(i))), ...
                    BinaryExpr(BinaryExpr.GTE, ...
                    dtc, ...
                    IntExpr(0)));
                codes{end + 1} = LustreEq(outputs{i}, ...
                    IteExpr(cond, ...
                    amp, ...
                    zero));
                %dtc = (-Phase) -> if (pre dtc >= Period - 1) then 0 else pre dtc + 1;
                dtc_cond = BinaryExpr(BinaryExpr.GTE, ...
                    UnaryExpr(UnaryExpr.PRE, dtc), ...
                    BinaryExpr(BinaryExpr.MINUS, ...
                    IntExpr(Period(i)), ...
                    IntExpr(1)));
                codes{end + 1} = LustreEq(dtc, ...
                    BinaryExpr(BinaryExpr.ARROW, ...
                    IntExpr(-PhaseDelay(i)), ...
                    IteExpr(dtc_cond, ...
                    IntExpr(0), ...
                    BinaryExpr(BinaryExpr.PLUS, ...
                    UnaryExpr(UnaryExpr.PRE, dtc), ...
                    IntExpr(1)))));
            end
            
            
            obj.addExternal_libraries('LustMathLib_lustrec_math');
            obj.setCode( codes );
            
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            obj.unsupported_options = {};
            if strcmp(blk.TimeSource, 'Use external signal')
                obj.addUnsupported_options(sprintf('Option "Use external signal" is not supported for block %s',...
                    blk.Origin_path));
                return;
            end
            options = obj.unsupported_options;
        end
    end
    
end

