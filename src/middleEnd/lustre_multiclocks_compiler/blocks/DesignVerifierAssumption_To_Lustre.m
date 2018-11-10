classdef DesignVerifierAssumption_To_Lustre < Block_To_Lustre
    %DesignVerifierAssumption_To_Lustre translates the Assumption block from SLDV.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        function obj = DesignVerifierAssumption_To_Lustre()
            obj.ContentNeedToBeTranslated = 0;
        end
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            inport_dt = blk.CompiledPortDataTypes.Inport{1};
            inport_lus_dt = SLX2LusUtils.get_lustre_dt(inport_dt);
            if isequal(blk.outEnabled, 'on')
                % Assumption block is passing the inputs in case the option
                % outEnabled is on
                [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
                obj.addVariable(outputs_dt);
                codes = cell(1, numel(outputs));
                for i=1:numel(outputs)
                    codes{i} = LustreEq(outputs{i}, inputs{i});
                end
                obj.setCode( codes );
            end
            if isequal(blk.enabled, 'off') ...
                    || isequal(blk.customAVTBlockType, 'Test Condition')
                % block is not activated or not Assumption
                return;
            end
            try
                code = DesignVerifierAssumption_To_Lustre.getAssumptionExpr(...
                    blk, inputs, inport_lus_dt);
                if ~isempty(code)
                    obj.addCode(AssertExpr(code));
                end
            catch me
                display_msg(me.getReport(),  MsgType.DEBUG, ...
                    'DesignVerifierAssumption_To_Lustre', '');
                display_msg(...
                    sprintf('Expression "%s" is not supported in block %s.', ...
                    blk.intervals, HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, ...
                    'DesignVerifierAssumption_To_Lustre', '');
            end
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static)
        function exp = getIntervalExpr(x, xDT, interval)
            if interval.lowIncluded
                op1 = BinaryExpr.LTE;
            else
                op1 = BinaryExpr.LT;
            end
            if interval.highIncluded
                op2 = BinaryExpr.LTE;
            else
                op2 = BinaryExpr.LT;
            end
            if strcmp(xDT, 'int')
                vLow = IntExpr(interval.low);
                vHigh = IntExpr(interval.high);
            elseif strcmp(xDT, 'bool')
                vLow = BooleanExpr(interval.low);
                vHigh = BooleanExpr(interval.high);
            else
                vLow = RealExpr(interval.low);
                vHigh = RealExpr(interval.high);
            end
            exp = BinaryExpr(BinaryExpr.AND, ...
                BinaryExpr(op1, vLow, x), ...
                BinaryExpr(op2, x, vHigh));
        end
        
        function code = getAssumptionExpr(blk, inputs, inport_lus_dt)
            %change inputs{1} to cell for code simplicity.
            code = {};
            if ~iscell(inputs{1})
                inputs{1} = {inputs{1}};
            end
            intervals = evalin('base', blk.intervals);
            %change to cell if needed
            if ~iscell(intervals)
                intervalsCell{1} = intervals;
            else
                intervalsCell = intervals;
            end
            conds = {};
            for i=1:numel(intervalsCell)
                if isa(intervalsCell{i}, 'Sldv.Interval')
                    conds2 = cell(1, numel(inputs{1}));
                    for inIdx=1:numel(inputs{1})
                        conds2{inIdx} = ...
                            DesignVerifierAssumption_To_Lustre.getIntervalExpr(...
                            inputs{1}{inIdx}, inport_lus_dt, intervalsCell{i});
                    end
                    conds{end+1} = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, ...
                        conds2);
                elseif isa(intervalsCell{i},  'Sldv.Point')
                    if strcmp(inport_lus_dt, 'int')
                        p = IntExpr(intervalsCell{i}.value);
                    elseif strcmp(inport_lus_dt, 'bool')
                        p = BooleanExpr(intervalsCell{i}.value);
                    else
                        p = RealExpr(intervalsCell{i}.value);
                    end
                    conds2 = cell(1, numel(inputs{1}));
                    for inIdx=1:numel(inputs{1})
                        conds2{inIdx} = BinaryExpr(...
                            BinaryExpr.EQ, inputs{1}{inIdx}, p);
                    end
                    conds{end+1} = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, ...
                        conds2);
                elseif numel(intervalsCell{i}) == 2
                    interval = struct();
                    interval.lowIncluded = 1;
                    interval.highIncluded = 1;
                    interval.low = intervalsCell{i}(1);
                    interval.high = intervalsCell{i}(2);
                    conds2 = cell(1, numel(inputs{1}));
                    for inIdx=1:numel(inputs{1})
                        conds2{inIdx} = ...
                            DesignVerifierAssumption_To_Lustre.getIntervalExpr(...
                            inputs{1}{inIdx}, inport_lus_dt, interval);
                    end
                    conds{end+1} = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, ...
                        conds2);
                elseif numel(intervalsCell{i}) == 1
                    if strcmp(inport_lus_dt, 'int')
                        p = IntExpr(intervalsCell{i});
                    elseif strcmp(inport_lus_dt, 'bool')
                        p = BooleanExpr(intervalsCell{i});
                    else
                        p = RealExpr(intervalsCell{i});
                    end
                    conds2 = cell(1, numel(inputs{1}));
                    for inIdx=1:numel(inputs{1})
                        conds2{inIdx} = BinaryExpr(...
                            BinaryExpr.EQ, inputs{1}{inIdx}, p);
                    end
                    conds{end+1} = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, ...
                        conds2);
                else
                    display_msg(...
                        sprintf('Expression "%s" is not supported in block %s.', ...
                        blk.intervals, HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, ...
                        'DesignVerifierAssumption_To_Lustre', '');
                    %the current condition will be ignored
                    continue;
                end
            end
            if ~isempty(conds)
                code = BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, conds);
            end
        end
    end
    
end

