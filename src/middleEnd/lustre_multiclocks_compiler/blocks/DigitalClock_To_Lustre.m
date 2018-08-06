classdef DigitalClock_To_Lustre < Block_To_Lustre
    %DigitalClock translates the DigitalClock block to external node
    %discretizing simulation time.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            [digitalsampleTime, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.SampleTime);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.InitialCondition, blk.Origin_path), ...
                    MsgType.ERROR, 'Constant_To_Lustre', '');
                return;
            end
            obj.addExternal_libraries('BlocksLib__DigitalClock');
            code = LustreEq(outputs{1}, ...
                NodeCallExpr('_DigitalClock', ...
                VarIdExpr(SLX2LusUtils.timeStepStr()), ...
                RealExpr(digitalsampleTime)));
            %sprintf('%s = _DigitalClock(%s, %.15f);\n\t', outputs{1},...
            %    SLX2LusUtils.timeStepStr(), digitalsampleTime);
            obj.setCode( code);
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
    end
    
end

