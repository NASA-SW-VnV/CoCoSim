function code = getAssumptionExpr(blk, inputs, inport_lus_dt)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
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
                    nasa_toLustre.blocks.DesignVerifierAssumption_To_Lustre.getIntervalExpr(...
                    inputs{1}{inIdx}, inport_lus_dt, intervalsCell{i});
            end
            conds{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                conds2);
        elseif isa(intervalsCell{i},  'Sldv.Point')
            if strcmp(inport_lus_dt, 'int')
                p = nasa_toLustre.lustreAst.IntExpr(intervalsCell{i}.value);
            elseif strcmp(inport_lus_dt, 'bool')
                p = nasa_toLustre.lustreAst.BooleanExpr(intervalsCell{i}.value);
            else
                p = nasa_toLustre.lustreAst.RealExpr(intervalsCell{i}.value);
            end
            conds2 = cell(1, numel(inputs{1}));
            for inIdx=1:numel(inputs{1})
                conds2{inIdx} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.EQ, inputs{1}{inIdx}, p);
            end
            conds{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
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
                    nasa_toLustre.blocks.DesignVerifierAssumption_To_Lustre.getIntervalExpr(...
                    inputs{1}{inIdx}, inport_lus_dt, interval);
            end
            conds{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                conds2);
        elseif numel(intervalsCell{i}) == 1
            if strcmp(inport_lus_dt, 'int')
                p = nasa_toLustre.lustreAst.IntExpr(intervalsCell{i});
            elseif strcmp(inport_lus_dt, 'bool')
                p = nasa_toLustre.lustreAst.BooleanExpr(intervalsCell{i});
            else
                p = nasa_toLustre.lustreAst.RealExpr(intervalsCell{i});
            end
            conds2 = cell(1, numel(inputs{1}));
            for inIdx=1:numel(inputs{1})
                conds2{inIdx} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.EQ, inputs{1}{inIdx}, p);
            end
            conds{end+1} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
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
        code = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.OR, conds);
    end
end

