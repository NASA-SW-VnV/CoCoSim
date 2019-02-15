function [body, vars] = addFinalCode_with_interpolation(outputs,inputs,...
        blk_name,blkParams,blk,N_shape_node,...
        coords_node,lusInport_dt,shapeNodeSign,...
        u_node, lus_backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    % This function carries out the interpolation depending on algorithm
    % option.  For the flat option, the value at the lower bounding
    % breakpoint is used. For the nearest option, the closest
    % bounding node for each dimension is used.  For the above option, the 
    % value at the upper bounding breakpoint is used.  We are not
    % calculating the distance from the interpolated point to each
    % of the bounding node on the polytop containing the
    % interpolated point.  For the "clipped" extrapolation option, the nearest
    % breakpoint in each dimension is used. Cubic spline is not
    % supported
    body = {};
    vars = {};
    InterpMethod = blkParams.InterpMethod;
    NumberOfTableDimensions = blkParams.NumberOfTableDimensions;
    BreakpointsForDimension = blkParams.BreakpointsForDimension;
    numBoundNodes = 2^blkParams.NumberOfTableDimensions;
    ExtrapMethod = blkParams.ExtrapMethod;

    % clipping
    clipped_inputs = cell(1,NumberOfTableDimensions);

    for i=1:NumberOfTableDimensions
        clipped_inputs{i} = VarIdExpr(sprintf('%s_clip_input_%d',blk_name,i));
        %vars = sprintf('%s\t%s:%s;\n',vars,clipped_inputs{i},lusInport_dt);
        vars{end+1} = LustreVar(clipped_inputs{i},lusInport_dt);
        if strcmp(ExtrapMethod,'Clip')
            if blkParams.isLookupTableDynamic
                conds{1} = BinaryExpr(BinaryExpr.LT,inputs{i}{1}, coords_node{i,1}, [], LusBackendType.isLUSTREC(lus_backend));
                conds{2} = BinaryExpr(BinaryExpr.GT,inputs{i}{1}, coords_node{i,2}, [], LusBackendType.isLUSTREC(lus_backend));                        
            else
                epsilon = Lookup_nD_To_Lustre.calculate_eps(BreakpointsForDimension{i}, 1);
                conds{1} = BinaryExpr(BinaryExpr.LT,inputs{i}{1}, coords_node{i,1}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                epsilon = Lookup_nD_To_Lustre.calculate_eps(BreakpointsForDimension{i}, 2);
                conds{2} = BinaryExpr(BinaryExpr.GT,inputs{i}{1}, coords_node{i,2}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
            end
            thens{1} = coords_node{i,1};
            thens{2} = coords_node{i,2};
            thens{3} = inputs{i}{1};
            rhs = IteExpr.nestedIteExpr(conds,thens);
            body{end+1} = LustreEq(clipped_inputs{i},rhs);
        else
            %body = sprintf('%s%s = %s ;\n\t', body,clipped_inputs{i},inputs{i}{1});
            body{end+1} = LustreEq(clipped_inputs{i},inputs{i}{1});
        end
    end

    if strcmp(InterpMethod,'Linear')
        % calculating linear shape function value
        denom_terms = cell(1,NumberOfTableDimensions);
        for i=1:NumberOfTableDimensions
            %denom = sprintf('%s*(%s-%s)',denom,coords_node{i,2},coords_node{i,1});
            denom_terms{i} = BinaryExpr(BinaryExpr.MINUS,coords_node{i,2},coords_node{i,1});
        end
        denom = BinaryExpr.BinaryMultiArgs(BinaryExpr.MULTIPLY,denom_terms);

        for i=1:numBoundNodes
            numerator_terms = cell(1,NumberOfTableDimensions);
            for j=1:NumberOfTableDimensions
                if shapeNodeSign(i,j)==-1
                    %code = sprintf('%s*(%s-%s)',code,coords_node{j,2},clipped_inputs{j});
                    numerator_terms{j} = BinaryExpr(BinaryExpr.MINUS,coords_node{j,2},clipped_inputs{j});
                else
                    %code = sprintf('%s*(%s-%s)',code,clipped_inputs{j},coords_node{j,1});
                    numerator_terms{j} = BinaryExpr(BinaryExpr.MINUS,clipped_inputs{j},coords_node{j,1});
                end
            end
            %body = sprintf('%s%s = (%s)/%s ;\n\t', body,N_shape_node{i}, code,denom);
            numerator = BinaryExpr.BinaryMultiArgs(BinaryExpr.MULTIPLY,numerator_terms);
            body{end+1} = LustreEq(N_shape_node{i},BinaryExpr(BinaryExpr.DIVIDE,numerator,denom));
        end
    else  % Cubic spline  % not yet
        display_msg(sprintf('Cubic spline is not yet supported  in block %s',...
            HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
    end

    %code = zero;
    terms = cell(1,numBoundNodes);
    for i=1:numBoundNodes
        %code = sprintf('%s+%s*%s ',code,N_shape_node{i},u_node{i});
        terms{i} = BinaryExpr(BinaryExpr.MULTIPLY,N_shape_node{i},u_node{i});
    end

    %body = sprintf('%s%s =  %s ;\n\t', body, outputs{1}, code);
    rhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS,terms);
    body{end+1} = LustreEq(outputs{1},rhs);
end

