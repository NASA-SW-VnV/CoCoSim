function [body, vars] = addDirectLookupNodeCode(blkParams,index_node,...
    coords_node,coords_input,Ast_dimJump)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function carries out the interpolation/extrapolation for the 
    % direct method depending on the user selection for algorithm
    % option.  For the flat option, the value at the lower bounding
    % breakpoint is used unless the . For the nearest option, the closest
    % bounding node for each dimension is used.  For the above option, the 
    % value at the upper bounding breakpoint is used.  We are not
    % calculating the distance from the interpolated point to each
    % of the bounding node on the polytop containing the
    % interpolated point.  For the "clipped" extrapolation option, the nearest
    % breakpoint in each dimension is used. Cubic spline is not
    % supported
    
    InterpMethod = blkParams.InterpMethod;
    NumberOfTableDimensions = blkParams.NumberOfTableDimensions;          
    body = {};
    vars = {};
    direct_lookup_node = ...
        blkParams.direct_sol_inline_index_VarIdExpr;
    vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
        direct_lookup_node, 'int');
    for i=1:NumberOfTableDimensions
        vars{end+1} = nasa_toLustre.lustreAst.LustreVar(...
            blkParams.sol_subs_for_dim{i}, 'int');
        
        epsilon = [];
        if ~nasa_toLustre.blocks.PreLookup_To_Lustre.bpIsInputPort(blkParams)
            epsilon = ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.calculate_eps(...
                blkParams.BreakpointsForDimension{i}, 1);
        end
        
        if strcmp(InterpMethod,'Above')

            body{end+1} = ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_direct_method_above_using_coords(...
                index_node,coords_node, coords_input,i, blkParams, epsilon);
            
        elseif strcmp(InterpMethod,'Nearest')
            [vars_c,body_c] = ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_direct_method_nearest_using_coords(...
                index_node,coords_node, coords_input,i, blkParams,epsilon);
            
            body = [body  body_c];
            vars = [vars  vars_c];

        else % default is 'Flat', which is the same as 'Below' and 'Clip'?
            % if coordinate is greater or equal to higher boundary node then use higher
            % node, else use lower node         
            
            body{end+1} = ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_direct_method_flat_using_coords(...
                blkParams,index_node,coords_node, coords_input,i,epsilon);
            
        end
    end
    
    % calculating inline index from array indices
    % limit solution subscript to number of breakpoints in a dimension
    terms = cell(1,NumberOfTableDimensions);
    for j=1:NumberOfTableDimensions
        if j==1
            terms{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                blkParams.sol_subs_for_dim{j}, Ast_dimJump{j});
        else
            terms{j} = nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
                blkParams.sol_subs_for_dim{j},...
                nasa_toLustre.lustreAst.IntExpr(1)), ...
                Ast_dimJump{j});
        end
    end

    if NumberOfTableDimensions == 1
        rhs = terms{1};
    elseif NumberOfTableDimensions == 2
        rhs = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS,terms{1},terms{2});
    else
        rhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
            nasa_toLustre.lustreAst.BinaryExpr.PLUS,terms);
    end
    
    body{end+1} = nasa_toLustre.lustreAst.LustreEq(direct_lookup_node,rhs);
    
end

