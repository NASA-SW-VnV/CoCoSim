classdef Lookup_nD_To_Lustre < Block_To_Lustre
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
    %         mesh, then the polytop is a rectangle containing the
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
        
        function  write_code(obj, parent, blk, xml_trace, ~, backend, varargin)
                    
            % codes are shared between Lookup_nD_To_Lustre and LookupTableDynamic
            isLookupTableDynamic = 0;
            external_lib = '';
            [mainCodes, main_vars, nodeCodes] =  ...
                Lookup_nD_To_Lustre.get_code_to_write(parent, blk, xml_trace, isLookupTableDynamic,backend);
            if ~isempty(external_lib)
                obj.addExternal_libraries(external_lib);
            end
            obj.setCode(mainCodes);
            obj.addVariable(main_vars);
            obj.addExtenal_node(nodeCodes);
            
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};
            [blkParams.NumberOfTableDimensions, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfTableDimensions);
            if blkParams.NumberOfTableDimensions >= 7
                obj.unsupported_options{numel(obj.unsupported_options) + 1} = ...
                    sprintf('More than 7 dimensions is not support in block %s', blk.Origin_path);
            end
            if strcmp(blk.InterpMethod, 'Cubic spline')
                obj.unsupported_options{numel(obj.unsupported_options) + 1} = ...
                    sprintf('Cubic spline interpolation is not support in block %s', blk.Origin_path);
            end            	
            if strcmp(blk.DataSpecification, 'Lookup table object')
                obj.unsupported_options{numel(obj.unsupported_options) + 1} = ...
                    sprintf('Lookup table object option for DataSpecification is not support in block %s', blk.Origin_path);
            end                
            options = obj.unsupported_options;
        end
        
    end
    
    methods(Static)
        
        function [ mainCodes, main_vars, nodeCodes] =  ...
                get_code_to_write(parent, blk, xml_trace,isLookupTableDynamic,backend)
            
            % initialize
            indexDataType = 'int';
            blk_name = SLX2LusUtils.node_name_format(blk);
            ext_node_name = sprintf('%s_ext_node',blk_name);            
            
            % get block outputs
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            % get block inputs
            [inputs,lusInport_dt,zero,one] = ...
                Lookup_nD_To_Lustre.getBlockInputsNames_convInType2AccType(parent, blk,isLookupTableDynamic);
            
            % read block parameters
            blkParams = Lookup_nD_To_Lustre.readBlkParams(parent,blk,isLookupTableDynamic);
            
            % For n-D Lookup Table, if UseOneInputPortForAllInputData is
            % selected, Combine all input data to one input port
            inputs = Lookup_nD_To_Lustre.useOneInputPortForAllInputData(blk,isLookupTableDynamic,inputs,blkParams.NumberOfTableDimensions);
            
            % writing external node code
            %node header
            node_header = Lookup_nD_To_Lustre.getNodeCodeHeader(isLookupTableDynamic,...
                inputs,blk_name,outputs,ext_node_name);
            
            % declaring and defining table values
            [body, vars,table_elem] = Lookup_nD_To_Lustre.addTableCode(blkParams.Table,blk_name,...
                lusInport_dt,isLookupTableDynamic,inputs);
            % declaring and defining break points
            [body, vars,Breakpoints] = Lookup_nD_To_Lustre.addBreakpointCode(body,...
                vars,blkParams.BreakpointsForDimension,blk_name,lusInport_dt,isLookupTableDynamic,...
                inputs,blkParams.NumberOfTableDimensions);
            
            % get bounding nodes (corners of polygon surrounding input point)
            [body, vars,numBoundNodes,u_node,N_shape_node,coords_node,index_node] = ...
                Lookup_nD_To_Lustre.addBoundNodeCode(body,vars,blkParams.NumberOfTableDimensions,...
                blk_name,Breakpoints,blkParams.skipInterpolation,lusInport_dt,indexDataType,...
                blkParams.BreakpointsForDimension,inputs);
            
            % defining u
            % doing subscripts to index in Lustre.  Need subscripts, and
            % dimension jump.
            shapeNodeSign = Lookup_nD_To_Lustre.getShapeBoundingNodeSign(blkParams.NumberOfTableDimensions);
            [body, vars,dimJump] = ...
                Lookup_nD_To_Lustre.addDimJumpCode(body,vars,blkParams.NumberOfTableDimensions,...
                blk_name,indexDataType,blkParams.BreakpointsForDimension);
            
            [body, vars] = Lookup_nD_To_Lustre.addShapeFunctionCode(body, vars,...
                numBoundNodes,shapeNodeSign,blk_name,indexDataType,table_elem,...
                blkParams.NumberOfTableDimensions,index_node,dimJump,blkParams.skipInterpolation,u_node);
            
            % now that we have all needed variables, write final interp
            % code
            [body, vars] = Lookup_nD_To_Lustre.addFinalInterpCode(body, ...
                vars,outputs,inputs,blkParams.skipInterpolation,indexDataType,blk_name,...
                blkParams.InterpMethod,blkParams.NumberOfTableDimensions,numBoundNodes,blk,...
                N_shape_node,coords_node,lusInport_dt,blkParams.ExtrapMethod,one,...
                zero,shapeNodeSign,u_node,index_node,dimJump,table_elem);
                       
            if BackendType.isKIND2(backend)
                contractBody = Lookup_nD_To_Lustre.getContractBody(blkParams,inputs,outputs);
                contract = sprintf('(*@contract\n%s\n*)\n',contractBody);
                nodeCodes = sprintf('%s%s%slet\n\t%s\ntel',...
                    node_header, contract,vars, body);
            else
                nodeCodes = sprintf('%s%slet\n\t%s\ntel',...
                    node_header,vars, body);
            end
            main_vars = outputs_dt;
            mainCodes = Lookup_nD_To_Lustre.getMainCode(outputs,inputs,ext_node_name,isLookupTableDynamic);
            
        end
        
        function [body, vars] = addFinalInterpCode(body, vars,outputs,inputs,...
                skipInterpolation,indexDataType,blk_name,InterpMethod,...
                NumberOfTableDimensions,numBoundNodes,blk,N_shape_node,...
                coords_node,lusInport_dt,ExtrapMethod,one,zero,shapeNodeSign,...
                u_node,index_node,dimJump,table_elem)
            % This function carries out the interpolation depending on algorithm
            % option.  For the flat option, the value at the lower bounding
            % breakpoint is used. For the nearest option, the closest
            % bounding node for each dimension is used.  We are not
            % calculating the distance from the interpolated point to each
            % of the bounding node on the polytop containing the
            % interpolated point.  For the "clipped" extrapolation option, the nearest
            % breakpoint in each dimension is used. Cubic spline is not
            % supported
            if skipInterpolation
                returnTableIndex{1} =  sprintf('%s_retTableInd_%d',blk_name,1);
                vars = sprintf('%s\t%s:%s;\n',vars,returnTableIndex{1},indexDataType);
                
                if strcmp(InterpMethod,'Flat')
                    % defining returnTableIndex{1}
                    value = '0';
                    for j=1:NumberOfTableDimensions
                        
                        curIndex =  index_node{j,1};
                        if j==1
                            value = sprintf('%s + %s*%d',value,curIndex, dimJump(j));
                        else
                            value = sprintf('%s + (%s-1)*%d',value,curIndex, dimJump(j));
                        end
                    end
                else   % 'Nearest' case
                    % defining returnTableIndex{1}
                    disFromTableNode = {};
                    nearestIndex = {};
                    for i=1:NumberOfTableDimensions
                        disFromTableNode{i,1} = sprintf('%s_disFromTableNode_dim_%d_1',blk_name,i);
                        vars = sprintf('%s\t%s:%s;\n',vars,disFromTableNode{i,1},lusInport_dt);
                        disFromTableNode{i,2} = sprintf('%s_disFromTableNode_dim_%d_2',blk_name,i);
                        vars = sprintf('%s\t%s:%s;\n',vars,disFromTableNode{i,2},lusInport_dt);
                        body = sprintf('%s%s = %s - %s ;\n\t', body,disFromTableNode{i,1},inputs{i}{1},coords_node{i,1});
                        body = sprintf('%s%s = %s - %s ;\n\t', body,disFromTableNode{i,2},coords_node{i,2},inputs{i}{1});
                        
                        nearestIndex{i} = sprintf('%s_nearestIndex_dim_%d',blk_name,i);
                        vars = sprintf('%s%s:%s;\n',vars,nearestIndex{i},indexDataType);
                        
                        code = sprintf('%s = if(%s <= %s) then %s\n\t', nearestIndex{i},disFromTableNode{i,2},disFromTableNode{i,1},index_node{i,2});
                        body = sprintf('%s%s  else %s;\n\t', body,code, index_node{i,1});
                    end
                    
                    value = '0';
                    for j=1:NumberOfTableDimensions
                        if j==1
                            value = sprintf('%s + %s*%d',value,nearestIndex{j}, dimJump(j));
                        else
                            value = sprintf('%s + (%s-1)*%d',value,nearestIndex{j}, dimJump(j));
                        end
                    end
                end
                body = sprintf('%s%s = %s;\n\t', body,returnTableIndex{1}, value);
                % defining outputs{1}
                code = sprintf('%s = \n\t', outputs{1});
                for j=1:numel(table_elem)-1
                    if j==1
                        code = sprintf('%s  if(%s = %d) then %s\n\t', code, returnTableIndex{1},j,table_elem{j});
                    else
                        code = sprintf('%s  else if(%s = %d) then %s\n\t', code, returnTableIndex{1},j,table_elem{j});
                    end
                end
                body = sprintf('%s%s  else %s ;\n\t', body,code,table_elem{numel(table_elem)});
                
            else
                % clipping
                clipped_inputs = {};
                
                for i=1:NumberOfTableDimensions
                    clipped_inputs{i} = sprintf('%s_clip_input_%d',blk_name,i);
                    vars = sprintf('%s\t%s:%s;\n',vars,clipped_inputs{i},lusInport_dt);
                    if strcmp(ExtrapMethod,'Clip')
                        code = sprintf('%s = if(%s<%s) then %s \n\t', clipped_inputs{i}, inputs{i}{1}, coords_node{i,1}, coords_node{i,1});
                        code = sprintf('%s  else if(%s > %s) then %s\n\t', code, inputs{i}{1}, coords_node{i,2}, coords_node{i,2});
                        body = sprintf('%s%s  else %s ;\n\t', body,code,inputs{i}{1});
                    else
                        body = sprintf('%s%s = %s ;\n\t', body,clipped_inputs{i},inputs{i}{1});
                    end
                end
                
                if strcmp(InterpMethod,'Linear')
                    % calculating linear shape function value
                    denom = one;
                    for i=1:NumberOfTableDimensions
                        denom = sprintf('%s*(%s-%s)',denom,coords_node{i,2},coords_node{i,1});
                    end
                    denom = sprintf('(%s)',denom);
                    
                    for i=1:numBoundNodes
                        code = one;
                        for j=1:NumberOfTableDimensions
                            if shapeNodeSign(i,j)==-1
                                code = sprintf('%s*(%s-%s)',code,coords_node{j,2},clipped_inputs{j});
                            else
                                code = sprintf('%s*(%s-%s)',code,clipped_inputs{j},coords_node{j,1});
                            end
                        end
                        body = sprintf('%s%s = (%s)/%s ;\n\t', body,N_shape_node{i}, code,denom);
                    end
                else  % Cubic spline  % not yet
                    display_msg(sprintf('Cubic spline is not yet supported  in block %s',...
                        blk.Origin_path), MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
                end
                
                code = zero;
                for i=1:numBoundNodes
                    code = sprintf('%s+%s*%s ',code,N_shape_node{i},u_node{i});
                end
                
                body = sprintf('%s%s =  %s ;\n\t', body, outputs{1}, code);
            end
        end
        
        function [body, vars] = addShapeFunctionCode(body, vars,numBoundNodes,...
                shapeNodeSign,blk_name,indexDataType,table_elem,...
                NumberOfTableDimensions,index_node,dimJump,skipInterpolation,u_node)
            % This function defines and calculating shape function values for the
            % interpolation point
            boundingNodeIndex = {};
            nodeIndex = 0;
            for i=1:numBoundNodes
                nodeIndex= nodeIndex+1;
                dimSign = shapeNodeSign(nodeIndex,:);
                
                % declaring boundingNodeIndex{nodeIndex}
                boundingNodeIndex{nodeIndex} = sprintf('%s_bound_node_index_%d',blk_name,nodeIndex);
                vars = sprintf('%s\t%s:%s;\n',vars,boundingNodeIndex{nodeIndex},indexDataType);
                
                % defining boundingNodeIndex{nodeIndex}
                value = '0';
                for j=1:NumberOfTableDimensions
                    % dimSign(j): -1 is low, 1: high
                    if dimSign(j) == -1
                        curIndex =  index_node{j,1};
                    else
                        curIndex =  index_node{j,2};
                    end
                    if j==1
                        value = sprintf('%s + %s*%d',value,curIndex, dimJump(j));
                    else
                        value = sprintf('%s + (%s-1)*%d',value,curIndex, dimJump(j));
                    end
                end
                body = sprintf('%s%s = %s;\n\t', body,boundingNodeIndex{nodeIndex}, value);
                
                if ~skipInterpolation
                    % defining u_node{nodeIndex}
                    code = sprintf('%s = \n\t', u_node{nodeIndex});
                    for j=1:numel(table_elem)-1
                        if j==1
                            code = sprintf('%s  if(%s = %d) then %s\n\t', code, boundingNodeIndex{nodeIndex},j,table_elem{j});
                        else
                            code = sprintf('%s  else if(%s = %d) then %s\n\t', code, boundingNodeIndex{nodeIndex},j,table_elem{j});
                        end
                    end
                    body = sprintf('%s%s  else %s ;\n\t', body,code,table_elem{numel(table_elem)});
                end
                
            end
        end
        
        function [body, vars,dimJump] = ...
                addDimJumpCode(body,vars,NumberOfTableDimensions,blk_name,...
                indexDataType,BreakpointsForDimension)
            %  This function defines dimJump.  table breakpoints and values are inline in Lustre, the
            %  interpolation formulation uses index for each dimension.  We
            %  need to get the inline data from the dimension subscript.
            %  Function addDimJumpCode calculate the index jump in the inline when we
            %  change dimension subscript.  For example dimJump(2) = 3 means
            %  to increase subscript dimension 2 by 1, we have to jump 3
            %  spaces in the inline storage.
            dimJump = ones(1,NumberOfTableDimensions);
            L_dimjump = {};
            L_dimjump{1} =  sprintf('%s_dimJump_%d',blk_name,1);
            vars = sprintf('%s\t%s:%s;\n',vars,L_dimjump{1},indexDataType);
            body = sprintf('%s%s = %d;\n\t', body,L_dimjump{1}, dimJump(1));
            for i=2:NumberOfTableDimensions
                L_dimjump{i} =  sprintf('%s_dimJump_%d',blk_name,i);
                vars = sprintf('%s\t%s:%s;\n',vars,L_dimjump{i},indexDataType);
                for j=1:i-1
                    dimJump(i) = dimJump(i)*numel(BreakpointsForDimension{j});
                end
                body = sprintf('%s%s = %d;\n\t', body,L_dimjump{i}, dimJump(i));
            end
        end
        
        function [body, vars,numBoundNodes,u_node,N_shape_node,coords_node,index_node] = ...
                addBoundNodeCode(body,vars,NumberOfTableDimensions,...
                blk_name,Breakpoints,skipInterpolation,lusInport_dt,indexDataType,...
                BreakpointsForDimension,inputs)
            %  This function finds the bounding polytop which is required to define
            %  the shape functions.  For each dimension, there will be 2
            %  breakpoints that surround the coordinate of the interpolation
            %  point in that dimension.  For 2 dimensions, if the table is a
            %  mesh, then the polytop is a rectangle containing the
            %  interpolation point.
            
            numBoundNodes = 2^NumberOfTableDimensions;
            % defining nodes bounding element (coords_node{NumberOfTableDimensions,2}: dim1_low, dim1_high,
            % dim2_low, dim2_high,... dimn_low, dimn_high)
            
            % finding nodes bounding element
            coords_node = {};
            index_node = {};
            
            for i=1:NumberOfTableDimensions
                % low node for dimension i
                coords_node{i,1} = sprintf('%s_coords_dim_%d_1',blk_name,i);
                vars = sprintf('%s\t%s:%s;\n',vars,coords_node{i,1},lusInport_dt);
                
                index_node{i,1} = sprintf('%s_index_dim_%d_1',blk_name,i);
                vars = sprintf('%s\t%s:%s;\n',vars,index_node{i,1},indexDataType);
                
                % high node for dimension i
                coords_node{i,2} = sprintf('%s_coords_dim_%d_2',blk_name,i);
                vars = sprintf('%s\t%s:%s;\n',vars,coords_node{i,2},lusInport_dt);
                
                index_node{i,2} = sprintf('%s_index_dim_%d_2',blk_name,i);
                vars = sprintf('%s\t%s:%s;\n',vars,index_node{i,2},indexDataType);
                
                % looking for low node
                code = sprintf('%s = \n\t', coords_node{i,1});    % code for coordinate values
                index_code = sprintf('%s = \n\t', index_node{i,1});  % index_code for indices
                for j=numel(BreakpointsForDimension{i}):-1:1
                    if j==numel(BreakpointsForDimension{i})
                        
                        if ~skipInterpolation
                            % for extrapolation, we want to use the last 2
                            % nodes
                            code = sprintf('%s  if(%s >= %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j-1});
                            index_code = sprintf('%s  if(%s >= %s) then %d\n\t', index_code, inputs{i}{1},Breakpoints{i}{j},(j-1));
                        else
                            % for "flat" we want lower node to be last node
                            code = sprintf('%s  if(%s >= %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
                            index_code = sprintf('%s  if(%s >= %s) then %d\n\t', index_code, inputs{i}{1},Breakpoints{i}{j},(j));
                        end
                        
                    else
                        code = sprintf('%s  else if(%s >= %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
                        index_code = sprintf('%s  else if(%s >= %s) then %d\n\t', index_code, inputs{i}{1},Breakpoints{i}{j},j);
                    end
                    
                end
                
                body = sprintf('%s%s  else %d ;\n\t',body, index_code,1);
                body = sprintf('%s%s  else %s ;\n\t', body,code,Breakpoints{i}{1});
                
                % looking for high node
                code = sprintf('%s = \n\t', coords_node{i,2});
                index_code = sprintf('%s = \n\t', index_node{i,2});
                for j=numel(BreakpointsForDimension{i}):-1:1
                    if j==numel(BreakpointsForDimension{i})
                        code = sprintf('%s  if(%s >= %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
                        index_code = sprintf('%s  if(%s >= %s) then %d\n\t', index_code, inputs{i}{1},Breakpoints{i}{j},j);
                    else
                        code = sprintf('%s  else if(%s >= %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j+1});
                        index_code = sprintf('%s  else if(%s >= %s) then %d\n\t', index_code, inputs{i}{1},Breakpoints{i}{j},(j+1));
                    end
                end
                
                body = sprintf('%s%s  else %d ;\n\t', body,index_code,2);
                body = sprintf('%s%s  else %s ;\n\t', body,code,Breakpoints{i}{2});
            end
            
            % if flat, make inputs the lowest bounding node
            %returnTableIndex = {};
            u_node = {};
            N_shape_node = {};
            
            % declaring node value and shape function
            if ~skipInterpolation
                for i=1:numBoundNodes
                    % y results at the node of the element
                    u_node{i} = sprintf('%s_u_node_%d',blk_name,i);
                    vars = sprintf('%s\t%s:%s;\n',vars,u_node{i},lusInport_dt);
                    % shape function result at the node of the element
                    N_shape_node{i} = sprintf('%s_N_shape_%d',blk_name,i);
                    vars = sprintf('%s\t%s:%s;\n',vars,N_shape_node{i},lusInport_dt);
                end
            end
            
        end
        
        function [body,vars,table_elem] = ...
                addTableCode(Table,blk_name,lusInport_dt,isLookupTableDynamic,inputs)
            % This function defines the table values defined by users.
            table_elem = {};
            body = '';
            vars = 'var';
            for i=1:numel(Table)
                table_elem{i} = sprintf('%s_table_elem_%d',blk_name,i);
                vars = sprintf('%s\t%s:%s;\n',vars,table_elem{i},lusInport_dt);
                if ~isLookupTableDynamic
                    body = sprintf('%s%s = %.15f ;\n\t',body, table_elem{i}, Table(i));
                else
                    body = sprintf('%s%s = %s;\n\t',body, table_elem{i}, inputs{3}{i});
                end
                
                
            end
        end
        
        function [body,vars,Breakpoints] = ...
                addBreakpointCode(body,vars,BreakpointsForDimension,blk_name,...
                lusInport_dt,isLookupTableDynamic,inputs,NumberOfTableDimensions)
            % This function define the breakpoints defined by
            % users.
            for j = 1:NumberOfTableDimensions
                Breakpoints{j} = {};
                for i=1:numel(BreakpointsForDimension{j})
                    Breakpoints{j}{i} = sprintf('%s_Breakpoints_dim%d_%d',blk_name,j,i);
                    vars = sprintf('%s\t%s:%s;\n',vars,Breakpoints{j}{i},lusInport_dt);
                    if ~isLookupTableDynamic
                        body = sprintf('%s\t%s = %.15f ;\n', body, Breakpoints{j}{i}, BreakpointsForDimension{j}(i));
                    else
                        body = sprintf('%s\t%s = %s;\n', body, Breakpoints{j}{i}, inputs{2}{i});
                    end
                    
                end
            end
        end
        
        function node_header = getNodeCodeHeader(isLookupTableDynamic,inputs,blk_name,outputs,ext_node_name)
            node_inputs = '';
            if ~isLookupTableDynamic
                for i=1:numel(inputs)
                    node_inputs = sprintf('%s%s:real;\n', node_inputs,inputs{i}{1});
                end
            else
                node_inputs = {};
                node_inputs{1} = sprintf('%s:real', inputs{1}{1});
                for i=2:3
                    for j=1:numel(inputs{i})
                        node_inputs{end+1} = sprintf('%s:real', inputs{i}{j});
                    end
                end
                node_inputs = MatlabUtils.strjoin(node_inputs, '; ');
            end
            node_returns = '';
            node_returns = sprintf('%s%s:real;\n', node_returns, outputs{1});
            node_header = sprintf('node %s(%s)\nreturns(%s);\n',...
                ext_node_name, node_inputs, node_returns);
        end
        
        function codes = getMainCode(outputs,inputs,ext_node_name,isLookupTableDynamic)
            codes = {};
            for outIdx=1:numel(outputs)
                nodeCall_inputs = {};
                if isLookupTableDynamic
                    nodeCall_inputs{end+1} = inputs{1}{outIdx};
                    for i=2:numel(inputs)
                        nodeCall_inputs = [nodeCall_inputs, inputs{i}];
                    end
                else
                    for i=1:numel(inputs)
                        nodeCall_inputs{end+1} = inputs{i}{outIdx};
                    end
                end
                nodeCall_inputs = MatlabUtils.strjoin(nodeCall_inputs, ', ');
                
                codes{outIdx} = sprintf('%s =  %s(%s) ;\n\t', outputs{outIdx}, ext_node_name, nodeCall_inputs);
            end
            codes = MatlabUtils.strjoin(codes, '');
        end
        
        function inputs = useOneInputPortForAllInputData(blk,isLookupTableDynamic,inputs,NumberOfTableDimensions)
            if ~isLookupTableDynamic
                p_inputs = {};
                if strcmp(blk.UseOneInputPortForAllInputData, 'on')
                    dimLen = numel(inputs{1})/NumberOfTableDimensions;
                    for i=1:NumberOfTableDimensions
                        p_inputs{i} = inputs{1}((i-1)*dimLen+1:i*dimLen);
                    end
                    inputs = p_inputs;
                end
            end
        end
        
        function blkParams = readBlkParams(parent,blk,isLookupTableDynamic)
            
            blkParams = struct;
            blkParams.BreakpointsForDimension = {};
            blkParams.skipInterpolation = 0;
            blkParams.yIsBounded = 0;
            
            if strcmp(blk.DataSpecification, 'Lookup table object')
                display_msg(sprintf('Lookup table object fir DataSpecification in block %s is not supported',...
                    blk.Origin_path), ...
                    MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
            end
            
            % read blk
            if isLookupTableDynamic
                blkParams.NumberOfTableDimensions = 1;
                blkParams.BreakpointsForDimension{1} = inputs{2};
                % table
                blkParams.Table = inputs{3};
                % look up method
                if strcmp(blk.LookUpMeth, 'Interpolation-Extrapolation')
                    blkParams.InterpMethod = 'Linear';
                    blkParams.ExtrapMethod = 'Linear';
                elseif strcmp(blk.LookUpMeth, 'Interpolation-Use End Values')
                    blkParams.InterpMethod = 'Linear';
                    blkParams.ExtrapMethod  = 'Clip';
                    blkParams.yIsBounded = 1;
                elseif strcmp(blk.LookUpMeth, 'Use Input Nearest')
                    blkParams.InterpMethod = 'Nearest';
                    blkParams.ExtrapMethod  = 'Clip';
                    blkParams.yIsBounded = 1;
                elseif strcmp(blk.LookUpMeth, 'Use Input Below')
                    blkParams.InterpMethod = 'Flat';
                    blkParams.ExtrapMethod  = 'Clip';
                    blkParams.yIsBounded = 1;
                elseif strcmp(blk.LookUpMeth, 'Use Input Above')
                    blkParams.InterpMethod = 'Above';
                    blkParams.ExtrapMethod  = 'Clip';
                    blkParams.yIsBounded = 1;
                elseif strcmp(blk.InterpMethod, 'Cubic spline')
                    display_msg(sprintf('Cubic spline interpolation in block %s is not supported',...
                        blk.Origin_path), ...
                        MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
                else
                    blkParams.InterpMethod = 'Linear';
                    blkParams.ExtrapMethod = 'Linear';
                end
            else
                [blkParams.NumberOfTableDimensions, ~, ~] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfTableDimensions);
                [blkParams.Table, ~, ~] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Table);
                tableDims = size(blkParams.Table);
                
                if strcmp(blk.BreakpointsSpecification, 'Even spacing')
                    for i=1:blkParams.NumberOfTableDimensions
                        evalString = sprintf('[firstPoint, ~, ~] = Constant_To_Lustre.getValueFromParameter(parent, blk, blk.BreakpointsForDimension%dFirstPoint); ',i);
                        eval(evalString);  % read firstPoint
                        evalString = sprintf('[spacing, ~, ~] = Constant_To_Lustre.getValueFromParameter(parent, blk, blk.BreakpointsForDimension%dSpacing); ',i);
                        eval(evalString);  % read spacing      
                        curBreakPoint = [];
                        
                        for j=1:tableDims(i)
                            curBreakPoint(j) = firstPoint + (j-1)*spacing;
                        end
                        blkParams.BreakpointsForDimension{i} = curBreakPoint;
                    end                    
                else
                    for i=1:blkParams.NumberOfTableDimensions
                        evalString = sprintf('[blkParams.BreakpointsForDimension{i}, ~, ~] = Constant_To_Lustre.getValueFromParameter(parent, blk, blk.BreakpointsForDimension%d); ',i);
                        eval(evalString);
                    end
                end
                
                blkParams.InterpMethod = blk.InterpMethod;
                blkParams.ExtrapMethod = blk.ExtrapMethod;
                blkParams.skipInterpolation = 0;
                if strcmp(blkParams.InterpMethod,'Flat') || strcmp(blkParams.InterpMethod,'Nearest')
                    blkParams.skipInterpolation = 1;
                    blkParams.yIsBounded = 1;
                end
                if strcmp(blkParams.ExtrapMethod,'Clip')
                    blkParams.yIsBounded = 1;
                end
            end
            blkParams.tableMin = min(blkParams.Table(:));
            blkParams.tableMax = max(blkParams.Table(:));
        end
        
        function contractBody = getContractBody(blkParams,inputs,outputs)
            contractBody = {};
            if blkParams.yIsBounded
                contractBody{end+1} = sprintf('guarantee  %s >= %.15f;\n',outputs{1},blkParams.tableMin);
                contractBody{end+1} = sprintf('guarantee  %s <= %.15f;',outputs{1},blkParams.tableMax);
            else
                % if u is inside "outer most" polytop, then y is also
                % bounded by table min and max
                code1 = 'guarantee ';
                code2 = 'guarantee ';
                for i=1:numel(inputs)
                    code1 = sprintf('%s %s >= %.15f and ',code1,inputs{i}{1},min(blkParams.BreakpointsForDimension{i}));
                    code1 = sprintf('%s %s <= %.15f ',code1,inputs{i}{1},max(blkParams.BreakpointsForDimension{i}));
                    code2 = sprintf('%s %s >= %.15f and ',code2,inputs{i}{1},min(blkParams.BreakpointsForDimension{i}));
                    code2 = sprintf('%s %s <= %.15f ',code2,inputs{i}{1},max(blkParams.BreakpointsForDimension{i}));                    
                end       
                contractBody{end+1} = sprintf('%s => %s >= %.15f;',code1,outputs{1},blkParams.tableMin);
                contractBody{end+1} = sprintf('%s => %s <= %.15f;',code2,outputs{1},blkParams.tableMax);              
            end
            contractBody = MatlabUtils.strjoin(contractBody, '');
        end
        
        function shapeNodeSign = getShapeBoundingNodeSign(dims)
            % generating sign for nodes bounding element for up to 7
            % dimensions
            shapeNodeSign = [];
            if dims == 1
                shapeNodeSign = [-1;1];
                return;
            elseif dims == 2
                shapeNodeSign = [-1 -1;-1 1;1 -1; 1 1];
                return;
            elseif dims == 3
                shapeNodeSign = [-1 -1 -1;-1 -1 1;-1 1 -1; -1 1 1;1 -1 -1;1 -1 1;1 1 -1; 1 1 1];
                return;
            elseif dims == 4
                shapeNodeSign = [-1    -1    -1    -1;-1    -1    -1     1;-1    -1     1    -1;
                    -1    -1     1     1;-1     1    -1    -1;-1     1    -1     1;
                    -1     1     1    -1;-1     1     1     1;1    -1    -1    -1;
                    1    -1    -1     1;1    -1     1    -1;1    -1     1     1;1     1    -1    -1;
                    1     1    -1     1;1     1     1    -1;1     1     1     1     ];
                return;
            elseif dims == 5
                shapeNodeSign = [];
                index = 0;
                for i=1:2
                    for j=1:2
                        for k=1:2
                            for l=1:2
                                for m=1:2
                                    ai = (-1)^i;
                                    aj = (-1)^j;
                                    ak = (-1)^k;
                                    al = (-1)^l;
                                    am = (-1)^m;
                                    index = index + 1;
                                    shapeNodeSign(index,:) = [ai aj ak al am];
                                end
                            end
                        end
                    end
                end
                Ns{5} = shapeNodeSign;
                return;
            elseif dims == 6
                shapeNodeSign = [];
                index = 0;
                for i=1:2
                    for j=1:2
                        for k=1:2
                            for l=1:2
                                for m=1:2
                                    for n=1:2
                                        ai = (-1)^i;
                                        aj = (-1)^j;
                                        ak = (-1)^k;
                                        al = (-1)^l;
                                        am = (-1)^m;
                                        an = (-1)^n;
                                        index = index + 1;
                                        shapeNodeSign(index,:) = [ai aj ak al am an];
                                    end
                                end
                            end
                        end
                    end
                end
                return;
            elseif dims == 7
                for i=1:2
                    for j=1:2
                        for k=1:2
                            for l=1:2
                                for m=1:2
                                    for n=1:2
                                        for o=1:2
                                            ai = (-1)^i;
                                            aj = (-1)^j;
                                            ak = (-1)^k;
                                            al = (-1)^l;
                                            am = (-1)^m;
                                            an = (-1)^n;
                                            ao = (-1)^o;
                                            index = index + 1;
                                            shapeNodeSign(index,:) = [ai aj ak al am an ao];
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                return;
            else
                return;
            end
        end
        
        function [inputs,lusInport_dt,zero,one] = ...
                getBlockInputsNames_convInType2AccType(parent, blk,isLookupTableDynamic)
            widths = blk.CompiledPortWidths.Inport;
            RndMeth = blk.RndMeth;
            max_width = max(widths);
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if ~isLookupTableDynamic && numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                [lusInport_dt, zero, one] = SLX2LusUtils.get_lustre_dt(inport_dt);
                %converts the input data type(s) to real
                
                if ~strcmp(lusInport_dt, 'real')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'real', RndMeth);
                    if ~isempty(external_lib)
                        %obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
        end
    end
    
end

