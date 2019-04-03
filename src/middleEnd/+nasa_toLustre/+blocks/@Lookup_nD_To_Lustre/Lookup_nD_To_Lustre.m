classdef Lookup_nD_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre ...
        & nasa_toLustre.blocks.BaseLookup
    % Lookup_nD_To_Lustre
    % This class will do linear interpolation for up to 7 dimensions.  For
    % some options like flat and nearest, values at the breakpoints are
    % returned.  For the "linear" option, the interpolation
    % technique used here is based on using shape functions (using finite
    % element terminology).  A reference describing this technique is
    % "Multi-Linear Interpolation" by Rick Wagner (Beach Cities Robotics,
    % First team 294).
    % http://bmia.bmt.tue.nl/people/BRomeny/Courses/8C080/Interpolation.pdf.
    % We are looking for y = f(u1,u2,...u7) where u1, u2 are coordinate 
    % values of dimension 1 and dimension 2 respectively for the point of interest.
    % We can obtain y from the interpolation equation
    % y(u1,u2,u3,...) = u1*N1(u1,u2,...) + u2*N2(u1,u2,...) + ...
    % u3*N3(u1,u2,...) + ... + u7*N7(u1,u2,...)
    % N1,N2 are shape functions for the 2 bounding nodes of dimension 1.  
    % N3, N4 are shape functions for the 2 bounding nodes of dimension 2.The shape functions
    % are defined by coordinates of the polytope with nodes (breakpoints in
    % simulink dialog) surrounding the point of interest.
    % The interpolation codes are done on the Lustre side.  In this
    % implementation, we do the main interpolation in Lustre external
    % nodes.  The main node just call the external node passing in the coordinates
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
    %         option.  For the flat option, the value at the lower bounding
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
        
        function  write_code(obj, parent, blk, xml_trace, ...
                lus_backend, varargin)
                    
            % codes are shared between Lookup_nD_To_Lustre and LookupTableDynamic 
            blkParams = ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.getInitBlkParams(blk);
            
            blkParams = obj.readBlkParams(parent,blk,blkParams);

            % get block outputs
            [outputs, ~] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(...
                parent, blk, [], xml_trace);
            
            % get block inputs and cast them to real
            widths = blk.CompiledPortWidths.Inport;
            numInputs = numel(widths);
            max_width = max(widths);
            RndMeth = blkParams.RndMeth;
            SaturateOnIntegerOverflow = blkParams.SaturateOnIntegerOverflow;          
            inputs = cell(1, numInputs);
            for i=1:numInputs
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                Lusinport_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{i});
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                %converts the input data type(s) to real if not real
                if ~strcmp(Lusinport_dt, 'real')
                    [external_lib, conv_format] = ...
                       nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(Lusinport_dt, 'real', RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end  
                        
            % For n-D Lookup Table, if UseOneInputPortForAllInputData is
            % selected, Combine all input data to one input port
            inputs = ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.useOneInputPortForAllInputData(...
                blk,inputs,blkParams.NumberOfTableDimensions);
            
            obj.addExternal_libraries({'LustMathLib_abs_real'});
            obj.create_lookup_nodes(blk,lus_backend,blkParams,outputs,inputs);


        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [NumberOfTableDimensions, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, ...
                blk, blk.NumberOfTableDimensions);
            if NumberOfTableDimensions >= 7
                obj.addUnsupported_options(sprintf(...
                    'More than 7 dimensions is not supported in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            if strcmp(blk.InterpMethod, 'Cubic spline')
                obj.addUnsupported_options(sprintf(...
                    'Cubic spline interpolation is not support in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end            	
            if strcmp(blk.DataSpecification, 'Lookup table object')
                obj.addUnsupported_options(sprintf(...
                    'Lookup table object option for DataSpecification is not support in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end                
            if NumberOfTableDimensions >= 3 ...
                    && isequal(blk.TableDataTypeStr, 'Inherit: Same as output') ...
                    && ~isequal(blk.CompiledPortDataTypes.Outport{1}, 'double') ...
                    && ~isequal(blk.CompiledPortDataTypes.Outport{1}, 'single')
                obj.addUnsupported_options(sprintf(...
                    'Lookup table "%s" has a Table DataType set different from double/Single which is not supported for dimension greater than 2.', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end

            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
                
        blkParams = readBlkParams(obj,parent,blk,blkParams)
        
        create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)

        extNode =  get_wrapper_node(obj,blk,blkParams,inputs,...
            outputs,preLookUpExtNode,interpolationExtNode)        
        
        [mainCode, main_vars] = getMainCode(obj, blk,outputs,inputs,...
            lookupWrapperExtNode,blkParams)
        
    end
    
    methods(Static)

        inputs = useOneInputPortForAllInputData(blk,lookupTableType,...
            inputs,NumberOfTableDimensions)
        
        [inputs,zero,one, external_lib] = ...
            getBlockInputsNames_convInType2AccType(parent, blk,...
            lookupTableType)
   
        extNode = get_pre_lookup_node(lus_backend,blkParams)

        extNode = get_interp_using_pre_node(blkParams, inputs)
 
        [body, vars,Ast_dimJump] = addDimJumpCode(...
            NumberOfTableDimensions,blk_name,indexDataType,blkParams)
       
        [body,vars,Breakpoints] = addBreakpointCode(blkParams,node_header)        
        
        [body, vars,coords_node,index_node] = addBoundNodeCode(...
            blkParams,Breakpoints,node_header,lus_backend)
      
        [body, vars, boundingi] = ...
            addBoundNodeInlineIndexCode(index_node,Ast_dimJump,blkParams)
        
        [body,vars,table_elem] = addTableCode(blkParams,node_header,inputs)
        
        [body, vars, retrieval_node] = addDirectLookupNodeCode(...
            blkParams,index_node,coords_node, coords_input ,...
            Ast_dimJump,lus_backend)
        
        shapeNodeSign = getShapeBoundingNodeSign(dims)

        [body, vars, boundingi] = addInlineIndexFromArrayIndicesCode(blkParams,...
            Breakpoints,node_header,lus_backend)

        body = addInlineIndexFromArrayIndices(...
            inline_list,element,index)
        
        [body, vars, N_shape_node] = addNodeWeightsCode(node_inputs,...
            coords_node,blkParams,lus_backend)
        
        [body, vars,u_node] = addUnodeCode(numBoundNodes,...
            boundingi,table_elem,blkParams)

        contractBody = getContractBody(blkParams,inputs,outputs)
        
        ep = calculate_eps(BP, j)
        
        y_interp = interp2points_2D(x1, y1, x2, y2, x_interp)
        
        function blkParams = getInitBlkParams(blk)
            blkParams = struct;
            blkParams.BreakpointsForDimension = {};
            blkParams.directLookup = 0;
            blkParams.yIsBounded = 0;
            blkParams.blk_name = ...
                nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            blkParams.RndMeth = 'Round';
            blkParams.SaturateOnIntegerOverflow = 'off';
        end


    end
    
end

