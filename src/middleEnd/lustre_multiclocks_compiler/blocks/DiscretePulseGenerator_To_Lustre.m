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
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
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
            
           if strcmp(PulseType, 'Sample based')
               % adapt parameters
               Period = Period * blk.CompiledSampleTime(1);
               PulseWidth = PulseWidth * blk.CompiledSampleTime(1);
               PhaseDelay = PhaseDelay * blk.CompiledSampleTime(1);
           else
               PulseWidth = PulseWidth*Period/100.0;
           end
            
           %displayString = sprintf('period: %f, width: %f, phase: %f ',...
           %Period, PulseWidth, PhaseDelay);
           %disp(displayString);
            
            
            ts = IRUtils.get_BlockDiagram_SampleTime(parent.Name);
            zero = RealExpr('0.0');
            blk_name = SLX2LusUtils.node_name_format(blk);
            dtc = sprintf('dtc_%s', blk_name);
            obj.addVariable(LustreVar( dtc, 'real'));
            epsilon = 0.0001*ts;
            codes = cell(1, numel(outputs_dt) + 1);
            for i=1:numel(outputs_dt)
                conds = cell(1, 2);
                thens = cell(1, 3);
                conds{1} = BinaryExpr(BinaryExpr.LT, ...
                                      VarIdExpr(SLX2LusUtils.timeStepStr()),...
                                      RealExpr(PhaseDelay));
                thens{1} = zero;                 
                conds{2} = BinaryExpr(BinaryExpr.LTE, ...
                                      VarIdExpr(dtc),...
                                      RealExpr(PulseWidth));
                thens{2} = RealExpr(Amplitude);
                thens{3} = zero;  
                codes{i} = LustreEq(outputs{i}, ...
                    IteExpr.nestedIteExpr(conds, thens));
                %codes{i} = sprintf('%s = if(__time_step < %.15f) then %.15f\n\t', outputs{i},PhaseDelay,zero);
                %codes{i} = sprintf('%s   else if(%s <= %.15f) then %.15f\n\t', codes{i},dtc,PulseWidth, Amplitude);
                %codes{i} = sprintf('%s   else %.15f;\n\t', codes{i},zero);
            end
            codes{end} = LustreEq(VarIdExpr(dtc), ...
                NodeCallExpr('fmod', ...
                            BinaryExpr.BinaryMultiArgs(BinaryExpr.MINUS, ...
                                       {VarIdExpr(SLX2LusUtils.timeStepStr()), ...
                                       RealExpr(PhaseDelay), ...
                                       RealExpr(epsilon)}), ...
                            RealExpr(Period)));
            %sprintf('%s = fmod((__time_step - %.15f + %f),%.15f);\n\t',dtc,PhaseDelay,epsilon, Period);
            
            obj.addExternal_libraries('LustMathLib_lustrec_math');
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
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

