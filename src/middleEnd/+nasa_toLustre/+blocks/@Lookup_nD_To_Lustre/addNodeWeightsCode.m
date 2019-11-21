function [body, vars, N_shape_node] = ...
    addNodeWeightsCode(node_inputs,coords_node,blkParams,lus_backend)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % This function defines and calculating shape function values for the
    % interpolation point
    InterpMethod = blkParams.InterpMethod;
    BreakpointsForDimension = blkParams.BreakpointsForDimension;
    ExtrapMethod = blkParams.ExtrapMethod;    
    NumberOfTableDimensions = blkParams.NumberOfTableDimensions;
    numBoundNodes = 2^NumberOfTableDimensions;
%     shapeNodeSign = ...
%         nasa_toLustre.blocks.Lookup_nD_To_Lustre.getShapeBoundingNodeSign(...
%         NumberOfTableDimensions);    
    body = cell(1,numBoundNodes+NumberOfTableDimensions);    
    vars = cell(1,numBoundNodes+NumberOfTableDimensions);            

    % N_shape_node variables
    N_shape_node = cell(1,numBoundNodes);    
    for i=1:numBoundNodes
        % shape function result at the node of the element
        N_shape_node{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('N_shape_%d',i));
        vars{i} = nasa_toLustre.lustreAst.LustreVar(...
            N_shape_node{i},'real');
    end
    
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
    
    % clipping
    clipped_inputs = cell(1,NumberOfTableDimensions);
    
    for i=1:NumberOfTableDimensions
        clipped_inputs{i} = nasa_toLustre.lustreAst.VarIdExpr(...
            sprintf('clip_input_%d',i));
        vars{numBoundNodes+i} = nasa_toLustre.lustreAst.LustreVar(...
            clipped_inputs{i},'real');
        if strcmp(ExtrapMethod,'Clip')
            if nasa_toLustre.blocks.PreLookup_To_Lustre.bpIsInputPort(blkParams)
                conds{1} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.LT,...
                    node_inputs{i}, coords_node{i,1}, []);
                conds{2} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.GT,...
                    node_inputs{i}, coords_node{i,2}, []);
            else
                epsilon = ...
                    nasa_toLustre.blocks.Lookup_nD_To_Lustre.calculate_eps(...
                    BreakpointsForDimension{i}, 1);
                conds{1} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.LT,...
                    node_inputs{i}, coords_node{i,1}, [], ...
                    LusBackendType.isLUSTREC(lus_backend), epsilon);
                epsilon = nasa_toLustre.blocks.Lookup_nD_To_Lustre.calculate_eps(...
                    BreakpointsForDimension{i}, 2);
                conds{2} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.GT,...
                    node_inputs{i}, coords_node{i,2}, [], ...
                    LusBackendType.isLUSTREC(lus_backend), epsilon);
            end
            thens{1} = coords_node{i,1};
            thens{2} = coords_node{i,2};
            thens{3} = node_inputs{i};
            rhs = nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(...
                conds,thens);
            body{i} = nasa_toLustre.lustreAst.LustreEq(...
                clipped_inputs{i},rhs);
        else
            body{i} = nasa_toLustre.lustreAst.LustreEq(...
                clipped_inputs{i},node_inputs{i});
        end
    end
    

        if strcmp(InterpMethod,'Cubic spline')

            display_msg(...
                sprintf('Cubic spline is not yet supported  in block %s',...
                HtmlItem.addOpenCmd(blk.Origin_path)), ...
                MsgType.ERROR, 'Lookup_nD_To_Lustre', '');            
        else
            % calculating linear shape function value
            denom_terms = cell(1,NumberOfTableDimensions);
            for i=1:NumberOfTableDimensions
                denom_terms{i} = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
                    coords_node{i,2},coords_node{i,1});
            end
            denom = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,denom_terms, 'real');
            
            for i=1:numBoundNodes
                numerator_terms = cell(1,NumberOfTableDimensions);
                for j=1:NumberOfTableDimensions
                    node2bin = strcat('000000', dec2bin(i-1));
                    if strcmp(node2bin(end-j+1), '0')%shapeNodeSign(i,j)==-1
                        numerator_terms{j} = ...
                            nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
                            coords_node{j,2},clipped_inputs{j});
                    else
                        numerator_terms{j} = ...
                            nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
                            clipped_inputs{j},coords_node{j,1});
                    end
                end
                numerator = ...
                    nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                    nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,...
                    numerator_terms, 'real');
                rhs = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.DIVIDE,...
                    numerator,denom);
                rhs.setOperandsDT('real');
                body{NumberOfTableDimensions+i} = nasa_toLustre.lustreAst.LustreEq(...
                    N_shape_node{i}, rhs);
            end

        end
    
end

