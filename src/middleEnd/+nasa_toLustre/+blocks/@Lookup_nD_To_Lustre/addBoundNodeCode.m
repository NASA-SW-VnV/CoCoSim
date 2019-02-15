function [body, vars,numBoundNodes,u_node,N_shape_node,coords_node,index_node] = ...
        addBoundNodeCode(blkParams,...
        blk_name,...
        Breakpoints,...
        lusInport_dt,...
        indexDataType, ...
        inputs,...
        lus_backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    %  This function finds the bounding polytop which is required to define
    %  the shape functions.  For each dimension, there will be 2
    %  breakpoints that surround the coordinate of the interpolation
    %  point in that dimension.  For 2 dimensions, if the table is a
    %  mesh, then the polytop is a rectangle containing the
    %  interpolation point.
    %  For the 'Flat' case, only lower index is needed.  
    %  For the 'Above" case, coords _2 is not needed
    body = {};
    vars = {};     
    skipInterpolation = blkParams.skipInterpolation;
    BreakpointsForDimension = blkParams.BreakpointsForDimension;
    numBoundNodes = 2^blkParams.NumberOfTableDimensions;
    InterpMethod = blkParams.InterpMethod;
    NumberOfTableDimensions = blkParams.NumberOfTableDimensions;
    % defining nodes bounding element (coords_node{NumberOfTableDimensions,2}: dim1_low, dim1_high,
    % dim2_low, dim2_high,... dimn_low, dimn_high)

    % finding nodes bounding element
    coords_node = {};
    index_node = {};

    for i=1:NumberOfTableDimensions

        % low node for dimension i                
        index_node{i,1} = VarIdExpr(...
            sprintf('%s_index_dim_%d_1',blk_name,i));
        index_node{i,2} = VarIdExpr(...
            sprintf('%s_index_dim_%d_2',blk_name,i));
        vars{end+1} = LustreVar(index_node{i,1},indexDataType);
        if ~strcmp(InterpMethod,'Flat')
            vars{end+1} = LustreVar(index_node{i,2},indexDataType);
        end

        coords_node{i,1} = VarIdExpr(...
            sprintf('%s_coords_dim_%d_1',blk_name,i));

        % high node for dimension i
        coords_node{i,2} = VarIdExpr(...
            sprintf('%s_coords_dim_%d_2',blk_name,i));

        if ~strcmp(InterpMethod,'Flat')
            vars{end+1} = LustreVar(coords_node{i,1},lusInport_dt);
            if ~strcmp(InterpMethod,'Above')
                vars{end+1} = LustreVar(coords_node{i,2},lusInport_dt);
            end
        end
        % looking for low node
        cond_index = {};
        then_index = {};
        cond_coords = {};
        then_coords = {};
        numberOfBreakPoint_cond = 0;

        for j=numel(BreakpointsForDimension{i}):-1:1
            if j==numel(BreakpointsForDimension{i})

                if ~skipInterpolation
                    % for extrapolation, we want to use the last 2
                    % nodes

                    numberOfBreakPoint_cond = numberOfBreakPoint_cond + 1;
                    if blkParams.isLookupTableDynamic
                        cond_index{end+1} =  BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend));
                        cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend));
                    else
                        epsilon = Lookup_nD_To_Lustre.calculate_eps(BreakpointsForDimension{i}, j);
                        cond_index{end+1} =  BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                        cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                    end
                    then_index{end+1} = IntExpr(j-1);
                    then_coords{end+1} = Breakpoints{i}{j-1};
                else
                    % for "flat" we want lower node to be last node
                    numberOfBreakPoint_cond = numberOfBreakPoint_cond + 1;
                    if blkParams.isLookupTableDynamic
                        cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend));
                        cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend));
                    else
                        epsilon = Lookup_nD_To_Lustre.calculate_eps(BreakpointsForDimension{i}, j);
                        cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                        cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                    end
                    then_index{end+1} = IntExpr(j);
                    then_coords{end+1} = Breakpoints{i}{j-1};
                end
            else
                numberOfBreakPoint_cond = numberOfBreakPoint_cond + 1;
                if blkParams.isLookupTableDynamic
                    cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend));
                    cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend));
                else
                    epsilon = Lookup_nD_To_Lustre.calculate_eps(BreakpointsForDimension{i}, j);
                    cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                    cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                end
                then_index{end+1} = IntExpr(j);
                then_coords{end+1} = Breakpoints{i}{j};                        
            end
        end                
        then_index{end+1} = IntExpr(1);
        then_coords{end+1} = Breakpoints{i}{1};

        index_1_rhs = IteExpr.nestedIteExpr(cond_index,then_index);
        coords_1_rhs = IteExpr.nestedIteExpr(cond_coords,then_coords);
        body{end+1} = LustreEq(index_node{i,1}, index_1_rhs);
        if ~strcmp(InterpMethod,'Flat')
            body{end+1} = LustreEq(coords_node{i,1}, coords_1_rhs);
        end

        % looking for high node
        cond_index = {};
        then_index = {};
        cond_coords = {};
        then_coords = {};

        for j=numel(BreakpointsForDimension{i}):-1:1
            if j==numel(BreakpointsForDimension{i})
                if blkParams.isLookupTableDynamic
                    cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend));
                    cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend));
                else
                    epsilon = Lookup_nD_To_Lustre.calculate_eps(BreakpointsForDimension{i}, j);
                    cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                    cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                end
                then_index{end+1} = IntExpr((j));
                then_coords{end+1} = Breakpoints{i}{j};

            else
                if blkParams.isLookupTableDynamic
                    cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend));
                    cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend));
                else
                    epsilon = Lookup_nD_To_Lustre.calculate_eps(BreakpointsForDimension{i}, j);
                    cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                    cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j}, [], LusBackendType.isLUSTREC(lus_backend), epsilon);
                end
                then_index{end+1} = IntExpr(j+1);
                then_coords{end+1} = Breakpoints{i}{j+1};
            end
        end

        then_index{end+1} = IntExpr(2);
        then_coords{end+1} = Breakpoints{i}{2};        

        index_2_rhs = IteExpr.nestedIteExpr(cond_index,then_index);
        coords_2_rhs = IteExpr.nestedIteExpr(cond_coords,then_coords);

        if ~strcmp(InterpMethod,'Flat')
            body{end+1} = LustreEq(index_node{i,2}, index_2_rhs);
            if ~strcmp(InterpMethod,'Above')
                body{end+1} = LustreEq(coords_node{i,2}, coords_2_rhs);   
            end
        end

    end

    % if flat, make inputs the lowest bounding node
    %returnTableIndex = {};
    u_node = {};
    N_shape_node = {};

    % declaring node value and shape function
    if ~skipInterpolation
        for i=1:numBoundNodes
            % y results at the node of the element
            u_node{i} = VarIdExpr(sprintf('%s_u_node_%d',blk_name,i));
            %vars = sprintf('%s\t%s:%s;\n',vars,u_node{i},lusInport_dt);
            vars{end+1} = LustreVar(u_node{i},lusInport_dt);
            % shape function result at the node of the element
            N_shape_node{i} = VarIdExpr(sprintf('%s_N_shape_%d',blk_name,i));
            %vars = sprintf('%s\t%s:%s;\n',vars,N_shape_node{i},lusInport_dt);
            vars{end+1} = LustreVar(N_shape_node{i},lusInport_dt);
        end
    end

end

