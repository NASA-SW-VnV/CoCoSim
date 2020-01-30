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
function code = getAssumptionExpr(blk, inputs, inport_lus_dt)

    
    %change inputs{1} to cell for code simplicity.
    code = {};
    if isempty(inputs)
        % connected to commented block or not connected
        code = nasa_toLustre.lustreAst.BoolExpr(true);
        return;
    elseif ~iscell(inputs{1})
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
                p = nasa_toLustre.lustreAst.BoolExpr(intervalsCell{i}.value);
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
                p = nasa_toLustre.lustreAst.BoolExpr(intervalsCell{i});
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

