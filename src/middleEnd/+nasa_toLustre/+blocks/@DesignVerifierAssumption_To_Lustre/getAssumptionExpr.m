
function code = getAssumptionExpr(blk, inputs, inport_lus_dt)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
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

