function OutMinMaxCheckCode(blk2LusObj, parent, blk, outputs, lus_dt, xml_trace, addAsAssertExpr)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if nargin < 7
        addAsAssertExpr = false;% it will be added as local property expression
    end
    if strcmp(blk.OutMin, '[]') && strcmp(blk.OutMax, '[]')
        % no need for the assertion.
        return;
    end
    try
        nb_outputs = numel(outputs);
        [outMin, ~, status] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent,...
            blk, blk.OutMin);
        if status
            outMin = [];
        end
        [outMax, ~, status] = ...
            nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent,...
            blk, blk.OutMax);
        if status
            outMax = [];
        end
        
        % adapt outMin and outMax to the dimension of output
        if ~isempty(outMin) && numel(outMin) < nb_outputs
            outMin = arrayfun(@(x) outMin(1), (1:nb_outputs));
        end
        if ~isempty(outMax) && numel(outMax) < nb_outputs
            outMax = arrayfun(@(x) outMax(1), (1:nb_outputs));
        end
        
        if ischar(lus_dt)
            % to be compatible with Bus signals
            lus_dt  = arrayfun(@(x) lus_dt, (1:nb_outputs), 'UniformOutput', 0);
        elseif iscell(lus_dt) && length(lus_dt) < nb_outputs
            % output is an array of a bus
            while (length(lus_dt) < nb_outputs)
                lus_dt = [lus_dt, lus_dt];
            end
        end
        
        prop_parts = {};
        for j=1:nb_outputs
            if ~strcmp(lus_dt{j}, 'int') && ~strcmp(lus_dt{j}, 'real')
                continue;
            end
            if ~isempty(outMin)
                lusMin =nasa_toLustre.utils.SLX2LusUtils.num2LusExp(outMin(j), lus_dt{j});
            end
            if ~isempty(outMax)
                lusMax =nasa_toLustre.utils.SLX2LusUtils.num2LusExp(outMax(j), lus_dt{j});
            end
            if isempty(outMin)
                prop_parts{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.LTE, outputs{j},...
                    lusMax);
            elseif isempty(outMax)
                prop_parts{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.LTE, lusMin, ...
                    outputs{j});
            else
                prop_parts{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                    nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.LTE, lusMin, outputs{j}), ...
                    nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.LTE, outputs{j}, lusMax));
            end
        end
        if ~isempty(prop_parts)
            prop = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                nasa_toLustre.lustreAst.BinaryExpr.AND, prop_parts);
            if addAsAssertExpr
                blk2LusObj.addCode(nasa_toLustre.lustreAst.AssertExpr(prop));
            else
                blk_name = nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
                propID = sprintf('%s_OUTMINMAX',blk_name);
                blk2LusObj.addCode(nasa_toLustre.lustreAst.LocalPropertyExpr(propID, prop));
                parent_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(parent);
                xml_trace.add_Property(blk.Origin_path, ...
                    parent_name, propID, 1, ...
                    CoCoBackendType.DED_OUTMINMAX);
            end
        end
    catch me
        
        display_msg(sprintf('Out Min Max check generation failed for block %s', blk.Origin_path),...
            MsgType.WARNING, 'OutMinMaxCheckCode','')
        display_msg(me.getReport(), MsgType.DEBUG, 'OutMinMaxCheckCode', '');
    end
    
end

