classdef Lookup_nD_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Lookup_nD_To_Lustre
    % This class will do linear interpolation for up to 7 dimensions.  For
    % some options like flat and nearest, values at the breakpoints are
    % returned.  For the "linear" option, the interpolation
    % technique used here is based on using shape functions (using finite
    % element terminology).  A reference describing this technique is
    % "Multi-Linear Interpolation" by Rick Wagner (Beach Cities Robotics,
    % First team 294).
    % http://bmia.bmt.tue.nl/people/BRomeny/Courses/8C080/Interpolation.pdf.
    % We are looking for y = f(u1,u2,...u7)   where u1, u2 are values of dimension 1 and
    % dimension 2 respectively.
    % We can obtain y from the interpolation equation
    % y(u1,u2,u3,...) = u1*N1(u1) + u2*N2(u2) + u3*N3(u3) + ... + u7*N7(u7)
    % N1,N2 are shape functions for dimension 1 and 2.  The shape functions
    % are defined by coordinates of the polytope with nodes (breakpoints in
    % simulink dialog) surrounding the point of interest.
    % The interpolation code are done on the Lustre side.  In this
    % implementation, we do the main interpolation in an Lustre external
    % node.  The main node just call the external node passing in the coordinates
    % of the point to be interpolated.  Table data is stored in the
    % external node.  The major steps for writing the external node are:
    %         1. define the breakpoints and table values defined by users (function
    %         addBreakpointCode and addBreakpointCode).
    %         2. finding the bounding polytop which is required to define
    %         the shape functions.  For each dimension, there will be 2
    %         breakpoints that surround the coordinate of the interpolation
    %         point in that dimension.  For 2 dimensions, if the table is a
    %         mesh, then the polytop is a quadrilateral containing the
    %         interpolation point.  Defining the bounding nodes is done in
    %         the function addBoundNodeCode.
    %         3. defining dimJump.  table breakpoints and values are inline in Lustre, the
    %         interpolation formulation uses index for each dimension.  We
    %         need to get the inline data from the dimension subscript.
    %         Function addDimJumpCode calculate the index jump in the inline when we
    %         change dimension subscript.  For example dimJump(2) = 3 means
    %         to increase subscript dimension 2 by 1, we have to jump 3
    %         spaces in the inline storage (addDimJumpCode).  See comments
    %         at the top of Assignment_To_Lustre.m for code example of
    %         getting inline index from subscripts of a multidimensional
    %         array.
    %         4. defining and calculating shape function values for the
    %         interpolation point (addShapeFunctionCode).
    %         5. carrying out the interpolation depending on algorithm
    %         option (addFinalInterpCode).  For the flat option, the value at the lower bounding
    %         breakpoint is used. For the nearest option, the closest
    %         bounding node for each dimension is used.  We are not
    %         calculating the distance from the interpolated point to each
    %         of the bounding node on the polytop containing the
    %         interpolated point. For the "clipped" extrapolation option, the nearest
    %         breakpoint in each dimension is used. Cubic spline is not
    %         supported
    %
    %         contract
    %         if u (interpolation point) lies inside the polytop, then y >=
    %         smallest table value and y <= largest table value.
    %         if interpolation method = 'Flat',  then y >=
    %         smallest table value and y <= largest table value.
    %         if interpolation method = 'Nearest',  then y >=
    %         smallest table value and y <= largest table value.    
    %         if extrapolation method = 'Clip',  then y >=
    %         smallest table value and y <= largest table value.        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, varargin)
                    
            % codes are shared between Lookup_nD_To_Lustre and LookupTableDynamic
            isLookupTableDynamic = 0;
            [mainCode, main_vars, extNode, external_lib] =  ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_code_to_write(...
                parent, blk, xml_trace, isLookupTableDynamic,lus_backend);
            if ~isempty(external_lib)
                obj.addExternal_libraries(external_lib);
            end
             
            obj.addExtenal_node(extNode);            
            obj.setCode(mainCode);
            obj.addVariable(main_vars);

        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [NumberOfTableDimensions, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfTableDimensions);
            if NumberOfTableDimensions >= 7
                obj.addUnsupported_options(sprintf('More than 7 dimensions is not supported in block %s', HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            if strcmp(blk.InterpMethod, 'Cubic spline')
                obj.addUnsupported_options(sprintf('Cubic spline interpolation is not support in block %s', HtmlItem.addOpenCmd(blk.Origin_path)));
            end            	
            if strcmp(blk.DataSpecification, 'Lookup table object')
                obj.addUnsupported_options(sprintf('Lookup table object option for DataSpecification is not support in block %s', HtmlItem.addOpenCmd(blk.Origin_path)));
            end                
            if NumberOfTableDimensions >= 3 ...
                    && isequal(blk.TableDataTypeStr, 'Inherit: Same as output') ...
                    && ~isequal(blk.CompiledPortDataTypes.Outport{1}, 'double') ...
                    && ~isequal(blk.CompiledPortDataTypes.Outport{1}, 'single')
                obj.addUnsupported_options(sprintf('Lookup table "%s" has a Table DataType set different from double/Single which is not supported for dimension greater than 2.', HtmlItem.addOpenCmd(blk.Origin_path)));
            end

            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
    end
    
    methods(Static)
        
        [ mainCode, main_vars, extNode, external_lib] =  ...
                get_code_to_write(parent, blk, xml_trace,isLookupTableDynamic,lus_backend)

        [body, vars] = addFinalCode_with_interpolation(outputs,inputs,...
                blk_name,blkParams,blk,N_shape_node,...
                coords_node,lusInport_dt,shapeNodeSign,...
                u_node, lus_backend)
   
        [body, vars] = addFinalCode_without_interpolation(...
                outputs,inputs,indexDataType,blk_name,...
                blkParams,...
                coords_node,lusInport_dt,...
                index_node,Ast_dimJump,table_elem, lus_backend)
   
        [body, vars] = addShapeFunctionCode(numBoundNodes,...
                shapeNodeSign,blk_name,indexDataType,table_elem,...
                NumberOfTableDimensions,index_node,Ast_dimJump,skipInterpolation,u_node)

        [body, vars,Ast_dimJump] = ...
                addDimJumpCode(NumberOfTableDimensions,blk_name,...
                indexDataType,BreakpointsForDimension)

        [body, vars,numBoundNodes,u_node,N_shape_node,coords_node,index_node] = ...
                addBoundNodeCode(blkParams,...
                blk_name,...
                Breakpoints,...
                lusInport_dt,...
                indexDataType, ...
                inputs,...
                lus_backend)
        
        [body,vars,table_elem] = ...
                addTableCode(Table,blk_name,lusInport_dt,isLookupTableDynamic,inputs)

        ep = calculate_eps(BP, j)

        [body,vars,Breakpoints] = ...
                addBreakpointCode(BreakpointsForDimension,blk_name,...
                lusInport_dt,isLookupTableDynamic,inputs,NumberOfTableDimensions)

        node_header = getNodeCodeHeader(isLookupTableDynamic,inputs,outputs,ext_node_name)
  
        codes = getMainCode(outputs,inputs,ext_node_name,...
                isLookupTableDynamic,output_conv_format)

        inputs = useOneInputPortForAllInputData(blk,isLookupTableDynamic,inputs,NumberOfTableDimensions)
        
        blkParams = readBlkParams(parent,blk,isLookupTableDynamic,inputs)
        
        contractBody = getContractBody(blkParams,inputs,outputs)

        shapeNodeSign = getShapeBoundingNodeSign(dims)

        [inputs,lusInport_dt,zero,one, external_lib] = ...
                getBlockInputsNames_convInType2AccType(parent, blk,isLookupTableDynamic)
        
        y_interp = interp2points_2D(x1, y1, x2, y2, x_interp)

    end
    
end

