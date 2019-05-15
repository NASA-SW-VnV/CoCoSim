function [body,vars,Breakpoints] = ...
        addBreakpointCode(blkParams,node_header)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % This function define the breakpoints defined by
    % users.
    body = {};
    vars = {};    
    Breakpoints = cell(1,blkParams.NumberOfAdjustedTableDimensions);
    % TODO allow for different type.
    for j = 1:blkParams.NumberOfAdjustedTableDimensions
        Breakpoints{j} = {};
        for i=1:numel(blkParams.BreakpointsForDimension{j})
            Breakpoints{j}{i} = nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('Breakpoints_dim%d_%d',j,i));
            vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
                Breakpoints{j}{i},'real');
            if ~(nasa_toLustre.blocks.PreLookup_To_Lustre.bpIsInputPort(blkParams))
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(...
                    Breakpoints{j}{i}, ...
                    nasa_toLustre.lustreAst.RealExpr(...
                    blkParams.BreakpointsForDimension{j}(i)));
            else
                body{end+1} = ...
                    nasa_toLustre.lustreAst.LustreEq(...
                    Breakpoints{j}{i}, node_header.inputs_name{1+i});
            end

        end
    end
end
