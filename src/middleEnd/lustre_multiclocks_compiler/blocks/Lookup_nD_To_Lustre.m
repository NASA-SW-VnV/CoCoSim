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
            [mainCode, main_vars, extNode, external_lib] =  ...
                Lookup_nD_To_Lustre.get_code_to_write(parent, blk, xml_trace, isLookupTableDynamic,backend);
            if ~isempty(external_lib)
                obj.addExternal_libraries(external_lib);
            end
             
            obj.addExtenal_node(extNode);            
            obj.setCode(mainCode);
            obj.addVariable(main_vars);

        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            [NumberOfTableDimensions, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfTableDimensions);
            if NumberOfTableDimensions >= 7
                obj.addUnsupported_options(sprintf('More than 7 dimensions is not supported in block %s', blk.Origin_path));
            end
            if strcmp(blk.InterpMethod, 'Cubic spline')
                obj.addUnsupported_options(sprintf('Cubic spline interpolation is not support in block %s', blk.Origin_path));
            end            	
            if strcmp(blk.DataSpecification, 'Lookup table object')
                obj.addUnsupported_options(sprintf('Lookup table object option for DataSpecification is not support in block %s', blk.Origin_path));
            end                
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
    end
    
    methods(Static)
        
        function [ mainCode, main_vars, extNode, external_lib] =  ...
                get_code_to_write(parent, blk, xml_trace,isLookupTableDynamic,backend)
            
            % initialize
            indexDataType = 'int';
            blk_name = SLX2LusUtils.node_name_format(blk);
            ext_node_name = sprintf('%s_ext_node',blk_name);            
            
            % get block outputs
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            % get block inputs
            [inputs,lusInport_dt,zero,one,  external_lib] = ...
                Lookup_nD_To_Lustre.getBlockInputsNames_convInType2AccType(parent, blk,isLookupTableDynamic);
            
            % read block parameters
            blkParams = Lookup_nD_To_Lustre.readBlkParams(parent,blk,isLookupTableDynamic,inputs);
            
            % For n-D Lookup Table, if UseOneInputPortForAllInputData is
            % selected, Combine all input data to one input port
            inputs = Lookup_nD_To_Lustre.useOneInputPortForAllInputData(blk,isLookupTableDynamic,inputs,blkParams.NumberOfTableDimensions);
            
            % writing external node code
            %node header
            node_header = Lookup_nD_To_Lustre.getNodeCodeHeader(isLookupTableDynamic,...
                inputs,outputs,ext_node_name);
            
            % declaring and defining table values
            [body, vars,table_elem] = Lookup_nD_To_Lustre.addTableCode(blkParams.Table,blk_name,...
                lusInport_dt,isLookupTableDynamic,inputs);
            body_all = body;
            vars_all = vars;
            % declaring and defining break points
            [body, vars,Breakpoints] = Lookup_nD_To_Lustre.addBreakpointCode(...
                blkParams.BreakpointsForDimension,blk_name,lusInport_dt,isLookupTableDynamic,...
                inputs,blkParams.NumberOfTableDimensions);
            body_all = [body_all  body];
            vars_all = [vars_all  vars];
            
            % get bounding nodes (corners of polygon surrounding input point)
            [body, vars,numBoundNodes,u_node,N_shape_node,coords_node,index_node] = ...
                Lookup_nD_To_Lustre.addBoundNodeCode(blkParams.NumberOfTableDimensions,...
                blk_name,Breakpoints,blkParams.skipInterpolation,lusInport_dt,indexDataType,...
                blkParams.BreakpointsForDimension,inputs);
            body_all = [body_all  body];
            vars_all = [vars_all  vars];            
            
            % defining u
            % doing subscripts to index in Lustre.  Need subscripts, and
            % dimension jump.
            shapeNodeSign = Lookup_nD_To_Lustre.getShapeBoundingNodeSign(blkParams.NumberOfTableDimensions);
            [body, vars,Ast_dimJump] = ...
                Lookup_nD_To_Lustre.addDimJumpCode(blkParams.NumberOfTableDimensions,...
                blk_name,indexDataType,blkParams.BreakpointsForDimension);
            body_all = [body_all  body];
            vars_all = [vars_all  vars];            
            
            [body, vars] = Lookup_nD_To_Lustre.addShapeFunctionCode(...
                numBoundNodes,shapeNodeSign,blk_name,indexDataType,table_elem,...
                blkParams.NumberOfTableDimensions,index_node,Ast_dimJump,blkParams.skipInterpolation,u_node);
            body_all = [body_all  body];
            vars_all = [vars_all  vars];
            
            % now that we have all needed variables, write final interp
            % code
            [bodyf, varsf] = Lookup_nD_To_Lustre.addFinalInterpCode( ...
                outputs,inputs,blkParams.skipInterpolation,indexDataType,blk_name,...
                blkParams.InterpMethod,blkParams.NumberOfTableDimensions,numBoundNodes,blk,...
                N_shape_node,coords_node,lusInport_dt,blkParams.ExtrapMethod,one,...
                zero,shapeNodeSign,u_node,index_node,Ast_dimJump,table_elem);
            body_all = [body_all  bodyf];
            vars_all = [vars_all  varsf];
            
            extNode = LustreNode();
            extNode.setName(node_header.NodeName)
            extNode.setInputs(node_header.Inputs);
            extNode.setOutputs( node_header.Outputs);
            extNode.setLocalVars(vars_all);
            extNode.setBodyEqs(body_all);
            extNode.setMetaInfo('external node code for doing Lookup_nD');
            
            if BackendType.isKIND2(backend) && ~isLookupTableDynamic
                contractBody = Lookup_nD_To_Lustre.getContractBody(blkParams,inputs,outputs);
                contract = LustreContract();
                contract.setBody(contractBody);
                extNode.setLocalContract(contract);
            end
            main_vars = outputs_dt;
            mainCode = Lookup_nD_To_Lustre.getMainCode(outputs,inputs,ext_node_name,isLookupTableDynamic);
            
        end
        
        function [body, vars] = addFinalInterpCode(outputs,inputs,...
                skipInterpolation,indexDataType,blk_name,InterpMethod,...
                NumberOfTableDimensions,numBoundNodes,blk,N_shape_node,...
                coords_node,lusInport_dt,ExtrapMethod,one,zero,shapeNodeSign,...
                u_node,index_node,Ast_dimJump,table_elem)
            % This function carries out the interpolation depending on algorithm
            % option.  For the flat option, the value at the lower bounding
            % breakpoint is used. For the nearest option, the closest
            % bounding node for each dimension is used.  We are not
            % calculating the distance from the interpolated point to each
            % of the bounding node on the polytop containing the
            % interpolated point.  For the "clipped" extrapolation option, the nearest
            % breakpoint in each dimension is used. Cubic spline is not
            % supported
            body = {};
            vars = {};
            if skipInterpolation
                returnTableIndex{1} =  VarIdExpr(sprintf('%s_retTableInd_%d',blk_name,1));
                %vars = sprintf('%s\t%s:%s;\n',vars,returnTableIndex{1},indexDataType);
                vars{end+1} = LustreVar(returnTableIndex{1}, indexDataType);
                terms = cell(1,NumberOfTableDimensions);
                if strcmp(InterpMethod,'Flat')
                    % defining returnTableIndex{1}
                    %value = '0';
                    %value_n = IntExpr(0);
                    
                    for j=1:NumberOfTableDimensions
                        
                        curIndex =  index_node{j,1};
                        if j==1
                            %value = sprintf('%s + %s*%d',value,curIndex, dimJump(j));
                            terms{j} = BinaryExpr(BinaryExpr.MULTIPLY,curIndex, Ast_dimJump{j});
                        else
                            %value = sprintf('%s + (%s-1)*%d',value,curIndex, dimJump(j));
                            terms{j} = BinaryExpr(BinaryExpr.MULTIPLY,BinaryExpr(BinaryExpr.MINUS,curIndex,IntExpr(1)), Ast_dimJump{j});
                        end
                    end
                else   % 'Nearest' case
                    % defining returnTableIndex{1}
                    disFromTableNode = cell(NumberOfTableDimensions,2);
                    nearestIndex = cell(1,NumberOfTableDimensions);
                    for i=1:NumberOfTableDimensions
                        disFromTableNode{i,1} = VarIdExpr(sprintf('%s_disFromTableNode_dim_%d_1',blk_name,i));
                        %vars = sprintf('%s\t%s:%s;\n',vars,disFromTableNode{i,1},lusInport_dt);
                        vars{end+1} = LustreVar(disFromTableNode{i,1},lusInport_dt);
                        disFromTableNode{i,2} = VarIdExpr(sprintf('%s_disFromTableNode_dim_%d_2',blk_name,i));
                        %vars = sprintf('%s\t%s:%s;\n',vars,disFromTableNode{i,2},lusInport_dt);
                        vars{end+1} = LustreVar(disFromTableNode{i,2},lusInport_dt);
                        %body = sprintf('%s%s = %s - %s ;\n\t', body,disFromTableNode{i,1},inputs{i}{1},coords_node{i,1});
                        %body = sprintf('%s%s = %s - %s ;\n\t', body,disFromTableNode{i,2},coords_node{i,2},inputs{i}{1});
                        body{end+1} = LustreEq(disFromTableNode{i,1},BinaryExpr(BinaryExpr.MINUS,inputs{i}{1},coords_node{i,1}));
                        body{end+1} = LustreEq(disFromTableNode{i,2},BinaryExpr(BinaryExpr.MINUS,coords_node{i,2},inputs{i}{1}));
                        
                        nearestIndex{i} = VarIdExpr(sprintf('%s_nearestIndex_dim_%d',blk_name,i));
                        %vars = sprintf('%s%s:%s;\n',vars,nearestIndex{i},indexDataType);
                        vars{end+1} = LustreVar(nearestIndex{i},indexDataType);
                        %code = sprintf('%s = if(%s <= %s) then %s\n\t', nearestIndex{i},disFromTableNode{i,2},disFromTableNode{i,1},index_node{i,2});
                        %body = sprintf('%s%s  else %s;\n\t', body,code, index_node{i,1});
                        condC = BinaryExpr(BinaryExpr.LTE,disFromTableNode{i,2},disFromTableNode{i,1});
                        body{end+1} = LustreEq(nearestIndex{i},IteExpr(condC,index_node{i,2},index_node{i,1}));
                    end
                    
                    %value = '0';
                    for j=1:NumberOfTableDimensions
                        if j==1
                            %value = sprintf('%s + %s*%d',value,nearestIndex{j}, dimJump(j));
                            terms{j} = BinaryExpr(BinaryExpr.MULTIPLY,nearestIndex{j}, Ast_dimJump{j});
                        else
                            %value = sprintf('%s + (%s-1)*%d',value,nearestIndex{j}, dimJump(j));
                            terms{j} = BinaryExpr(BinaryExpr.MULTIPLY,BinaryExpr(BinaryExpr.MINUS,nearestIndex{j},IntExpr(1)), Ast_dimJump{j});
                        end
                    end
                end
                %body = sprintf('%s%s = %s;\n\t', body,returnTableIndex{1}, value);
                if NumberOfTableDimensions == 1
                    rhs = terms{1};
                elseif NumberOfTableDimensions == 2
                    rhs = BinaryExpr(BinaryExpr.PLUS,terms{1},terms{2});
                else
                    rhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS,terms);
                end
                body{end+1} = LustreEq(returnTableIndex{1},rhs);
                
                % defining outputs{1}
                %code = sprintf('%s = \n\t', outputs{1});
                conds = cell(1,numel(table_elem)-1);
                thens = cell(1,numel(table_elem));
                for j=1:numel(table_elem)-1
                    conds{j} = BinaryExpr(BinaryExpr.EQ,returnTableIndex{1},IntExpr(j));
                    thens{j} = table_elem{j};
%                     if j==1
%                         code = sprintf('%s  if(%s = %d) then %s\n\t', code, returnTableIndex{1},j,table_elem{j});
%                     else
%                         code = sprintf('%s  else if(%s = %d) then %s\n\t', code, returnTableIndex{1},j,table_elem{j});
%                     end
                end
                %body = sprintf('%s%s  else %s ;\n\t', body,code,table_elem{numel(table_elem)});
                thens{numel(table_elem)} = table_elem{numel(table_elem)};
                if numel(table_elem) == 1
                    rhs = IteExpr(conds{1},thens{1},thens{2});
                else
                    rhs = IteExpr.nestedIteExpr(conds, thens);
                end
                body{end+1} = LustreEq(outputs{1},rhs);
            else
                % clipping
                clipped_inputs = cell(1,NumberOfTableDimensions);
                
                for i=1:NumberOfTableDimensions
                    clipped_inputs{i} = VarIdExpr(sprintf('%s_clip_input_%d',blk_name,i));
                    %vars = sprintf('%s\t%s:%s;\n',vars,clipped_inputs{i},lusInport_dt);
                    vars{end+1} = LustreVar(clipped_inputs{i},lusInport_dt);
                    if strcmp(ExtrapMethod,'Clip')
                        %code = sprintf('%s = if(%s<%s) then %s \n\t', clipped_inputs{i}, inputs{i}{1}, coords_node{i,1}, coords_node{i,1});
                        %code = sprintf('%s  else if(%s > %s) then %s\n\t', code, inputs{i}{1}, coords_node{i,2}, coords_node{i,2});
                        %body = sprintf('%s%s  else %s ;\n\t', body,code,inputs{i}{1});
                        conds{1} = BinaryExpr(BinaryExpr.LT,inputs{i}{1}, coords_node{i,1});
                        conds{2} = BinaryExpr(BinaryExpr.GT,inputs{i}{1}, coords_node{i,2});
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
                        blk.Origin_path), MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
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
        end
        
        function [body, vars] = addShapeFunctionCode(numBoundNodes,...
                shapeNodeSign,blk_name,indexDataType,table_elem,...
                NumberOfTableDimensions,index_node,Ast_dimJump,skipInterpolation,u_node)
            % This function defines and calculating shape function values for the
            % interpolation point
            body = {};   % body may grow if ~skipInterpolation
            vars = cell(1,numBoundNodes);            
            boundingi = cell(1,numBoundNodes);

            for i=1:numBoundNodes
                dimSign = shapeNodeSign(i,:);
                % declaring boundingi{i}
                boundingi{i} = VarIdExpr(sprintf('%s_bound_node_index_%d',blk_name,i));
                %vars = sprintf('%s\t%s:%s;\n',vars,boundingi{i},indexDataType);
                vars{i} = LustreVar(boundingi{i},indexDataType);
                
                % defining boundingi{i}
                %value = '0';
                terms = cell(1,NumberOfTableDimensions);
                for j=1:NumberOfTableDimensions
                    % dimSign(j): -1 is low, 1: high
                    if dimSign(j) == -1
                        curIndex =  index_node{j,1};
                    else
                        curIndex =  index_node{j,2};
                    end
                    if j==1
                        %value = sprintf('%s + %s*%d',value,curIndex, dimJump(j));
                        terms{j} = BinaryExpr(BinaryExpr.MULTIPLY,curIndex,Ast_dimJump{j});
                    else
                        %value = sprintf('%s + (%s-1)*%d',value,curIndex, dimJump(j));
                        terms{j} = BinaryExpr(BinaryExpr.MULTIPLY,...
                            BinaryExpr(BinaryExpr.MINUS,...
                                        curIndex, ...
                                        IntExpr(1)),...
                            Ast_dimJump{j});
                    end
                end
                %body = sprintf('%s%s = %s;\n\t', body,boundingi{i}, value);
                if NumberOfTableDimensions == 1
                    value = terms{1};
                else
                    value = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS,terms);
                end
                body{end+1} = LustreEq(boundingi{i},value);
                
                if ~skipInterpolation
                    % defining u_node{i}
                    %code = sprintf('%s = \n\t', u_node{i});
                    conds = cell(1,numel(table_elem)-1);
                    thens = cell(1,numel(table_elem));
                    for j=1:numel(table_elem)-1
%                        if j==1
                            %code = sprintf('%s  if(%s = %d) then %s\n\t', code, boundingi{i},j,table_elem{j});
                            conds{j} = BinaryExpr(BinaryExpr.EQ,boundingi{i},IntExpr(j));
                            thens{j} = table_elem{j};
%                         else
%                             %code = sprintf('%s  else if(%s = %d) then %s\n\t', code, boundingi{i},j,table_elem{j});
%                             conds{j} = BinaryExpr(BinaryExpr.EQ,boundingi{i},IntExpr(j));
%                             thens{j} = table_elem{j};                            
%                        end
                    end
                    %body = sprintf('%s%s  else %s ;\n\t', body,code,table_elem{numel(table_elem)});
                    thens{numel(table_elem)} = table_elem{numel(table_elem)};
                    rhs = IteExpr.nestedIteExpr(conds, thens);
                    body{end+1} = LustreEq(u_node{i},rhs);
                end
                
            end
        end
        
        function [body, vars,Ast_dimJump] = ...
                addDimJumpCode(NumberOfTableDimensions,blk_name,...
                indexDataType,BreakpointsForDimension)
            %  This function defines dimJump.  table breakpoints and values are inline in Lustre, the
            %  interpolation formulation uses index for each dimension.  We
            %  need to get the inline data from the dimension subscript.
            %  Function addDimJumpCode calculate the index jump in the inline when we
            %  change dimension subscript.  For example dimJump(2) = 3 means
            %  to increase subscript dimension 2 by 1, we have to jump 3
            %  spaces in the inline storage.
            body = cell(1,NumberOfTableDimensions);
            vars = cell(1,NumberOfTableDimensions);            
            dimJump = ones(1,NumberOfTableDimensions);
            L_dimjump = cell(1,NumberOfTableDimensions);
            L_dimjump{1} =  VarIdExpr(sprintf('%s_dimJump_%d',blk_name,1));
            Ast_dimJump = cell(1,NumberOfTableDimensions);
            Ast_dimJump{1} = IntExpr(1);
            %vars = sprintf('%s\t%s:%s;\n',vars,L_dimjump{1},indexDataType);
            vars{1} = LustreVar(L_dimjump{1},indexDataType);
            %body = sprintf('%s%s = %d;\n\t', body,L_dimjump{1}, dimJump(1));
            body{1} = LustreEq(L_dimjump{1},IntExpr(dimJump(1)));
            for i=2:NumberOfTableDimensions
                L_dimjump{i} =  VarIdExpr(sprintf('%s_dimJump_%d',blk_name,i));
                %vars = sprintf('%s\t%s:%s;\n',vars,L_dimjump{i},indexDataType);
                vars{i} = LustreVar(L_dimjump{i},indexDataType);
                for j=1:i-1
                    dimJump(i) = dimJump(i)*numel(BreakpointsForDimension{j});
                end
                %body = sprintf('%s%s = %d;\n\t', body,L_dimjump{i}, dimJump(i));
                body{i} = LustreEq(L_dimjump{i},IntExpr(dimJump(i)));
                Ast_dimJump{i} = IntExpr(dimJump(i));
            end
        end
        
        function [body, vars,numBoundNodes,u_node,N_shape_node,coords_node,index_node] = ...
                addBoundNodeCode(NumberOfTableDimensions,...
                blk_name,Breakpoints,skipInterpolation,lusInport_dt,indexDataType,...
                BreakpointsForDimension,inputs)
            %  This function finds the bounding polytop which is required to define
            %  the shape functions.  For each dimension, there will be 2
            %  breakpoints that surround the coordinate of the interpolation
            %  point in that dimension.  For 2 dimensions, if the table is a
            %  mesh, then the polytop is a rectangle containing the
            %  interpolation point.
            body = {};
            vars = {};            
            numBoundNodes = 2^NumberOfTableDimensions;
            % defining nodes bounding element (coords_node{NumberOfTableDimensions,2}: dim1_low, dim1_high,
            % dim2_low, dim2_high,... dimn_low, dimn_high)
            
            % finding nodes bounding element
            coords_node = {};
            index_node = {};
            
            for i=1:NumberOfTableDimensions
                % low node for dimension i
                coords_node{i,1} = VarIdExpr(...
                    sprintf('%s_coords_dim_%d_1',blk_name,i));
                vars{end+1} = LustreVar(coords_node{i,1},lusInport_dt);
                
                index_node{i,1} = VarIdExpr(...
                    sprintf('%s_index_dim_%d_1',blk_name,i));
                vars{end+1} = LustreVar(index_node{i,1},indexDataType);
                
                % high node for dimension i
                coords_node{i,2} = VarIdExpr(...
                    sprintf('%s_coords_dim_%d_2',blk_name,i));
                vars{end+1} = LustreVar(coords_node{i,2},lusInport_dt);
                
                index_node{i,2} = VarIdExpr(...
                    sprintf('%s_index_dim_%d_2',blk_name,i));
                vars{end+1} = LustreVar(index_node{i,2},indexDataType);
                
                % looking for low node
                cond_index = {};
                then_index = {};
                cond_coords = {};
                then_coords = {};
                %code = sprintf('%s = \n\t', coords_node{i,1});    % code for coordinate values                
                %index_code = sprintf('%s = \n\t', index_node{i,1});  % index_code for indices
                numberOfBreakPoint_cond = 0;
                %fprintf('i: %d, numel BreakpointsForDimension(i): %d\n',i,numel(BreakpointsForDimension{i}));
                for j=numel(BreakpointsForDimension{i}):-1:1
                    if j==numel(BreakpointsForDimension{i})
                        
                        if ~skipInterpolation
                            % for extrapolation, we want to use the last 2
                            % nodes
                            %code = sprintf('%s  if(%s >= %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j-1});
                            %index_code = sprintf('%s  if(%s >= %s) then %d\n\t', index_code, inputs{i}{1},Breakpoints{i}{j},(j-1));
                            
                            numberOfBreakPoint_cond = numberOfBreakPoint_cond + 1;
                            cond_index{end+1} =  BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j});
                            then_index{end+1} = IntExpr(j-1);
                            cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j});
                            then_coords{end+1} = Breakpoints{i}{j-1};
                        else
                            % for "flat" we want lower node to be last node
                            %code = sprintf('%s  if(%s >= %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
                            %index_code = sprintf('%s  if(%s >= %s) then %d\n\t', index_code, inputs{i}{1},Breakpoints{i}{j},(j));
                            
                            numberOfBreakPoint_cond = numberOfBreakPoint_cond + 1;
                            cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j});
                            then_index{end+1} = IntExpr(j);
                            cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j});
                            then_coords{end+1} = Breakpoints{i}{j-1};                            
                            
                        end
                        
                    else
                        %code = sprintf('%s  else if(%s >= %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
                        %index_code = sprintf('%s  else if(%s >= %s) then %d\n\t', index_code, inputs{i}{1},Breakpoints{i}{j},j);
                        
                        numberOfBreakPoint_cond = numberOfBreakPoint_cond + 1;
                        cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j});
                        then_index{end+1} = IntExpr(j);
                        cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j});
                        then_coords{end+1} = Breakpoints{i}{j};
                        
                    end                    
                end                
                %body = sprintf('%s%s  else %d ;\n\t',body, index_code,1);
                %body = sprintf('%s%s  else %s ;\n\t', body,code,Breakpoints{i}{1});
                then_index{end+1} = IntExpr(1);
                then_coords{end+1} = Breakpoints{i}{1};
                
                index_1_rhs = IteExpr.nestedIteExpr(cond_index,then_index);
                coords_1_rhs = IteExpr.nestedIteExpr(cond_coords,then_coords);
                body{end+1} = LustreEq(index_node{i,1}, index_1_rhs);
                body{end+1} = LustreEq(coords_node{i,1}, coords_1_rhs);
                %fprintf('i: %d, numberOfBreakPoint_cond: %d\n',i,numberOfBreakPoint_cond);
                
                % looking for high node
                cond_index = {};
                then_index = {};
                cond_coords = {};
                then_coords = {};                
%                 code = sprintf('%s = \n\t', coords_node{i,2});
%                 index_code = sprintf('%s = \n\t', index_node{i,2});
                for j=numel(BreakpointsForDimension{i}):-1:1
                    if j==numel(BreakpointsForDimension{i})
                        %code = sprintf('%s  if(%s >= %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
                        %index_code = sprintf('%s  if(%s >= %s) then %d\n\t', index_code, inputs{i}{1},Breakpoints{i}{j},j);

                        cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j});
                        then_index{end+1} = IntExpr((j));
                        cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j});
                        then_coords{end+1} = Breakpoints{i}{j};
                    
                    else
                        %code = sprintf('%s  else if(%s >= %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j+1});
                        %index_code = sprintf('%s  else if(%s >= %s) then %d\n\t', index_code, inputs{i}{1},Breakpoints{i}{j},(j+1));
                       
                        cond_index{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j});
                        then_index{end+1} = IntExpr(j+1);
                        cond_coords{end+1} = BinaryExpr(BinaryExpr.GTE, inputs{i}{1},Breakpoints{i}{j});
                        then_coords{end+1} = Breakpoints{i}{j+1};
                                            
                    end
                end
                
                %body = sprintf('%s%s  else %d ;\n\t', body,index_code,2);
                %body = sprintf('%s%s  else %s ;\n\t', body,code,Breakpoints{i}{2});
                
                then_index{end+1} = IntExpr(2);
                then_coords{end+1} = Breakpoints{i}{2};        
                
                
                index_2_rhs = IteExpr.nestedIteExpr(cond_index,then_index);
                coords_2_rhs = IteExpr.nestedIteExpr(cond_coords,then_coords);
                body{end+1} = LustreEq(index_node{i,2}, index_2_rhs);
                body{end+1} = LustreEq(coords_node{i,2}, coords_2_rhs);                
                
                
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
        
        function [body,vars,table_elem] = ...
                addTableCode(Table,blk_name,lusInport_dt,isLookupTableDynamic,inputs)
            % This function defines the table values defined by users.
            table_elem = cell(1, numel(Table));
            body = cell(1, numel(Table));
            vars = cell(1, numel(Table));
            for i=1:numel(Table)
                table_elem{i} = VarIdExpr(...
                    sprintf('%s_table_elem_%d',blk_name,i));
                vars{i} = LustreVar(table_elem{i},lusInport_dt);
                if ~isLookupTableDynamic
                    body{i} = LustreEq(table_elem{i}, RealExpr(Table(i)));
                else
                    body{i} = LustreEq(table_elem{i}, inputs{3}{i});
                end
                
                
            end
        end
        
        function [body,vars,Breakpoints] = ...
                addBreakpointCode(BreakpointsForDimension,blk_name,...
                lusInport_dt,isLookupTableDynamic,inputs,NumberOfTableDimensions)
            % This function define the breakpoints defined by
            % users.
            body = {};
            vars = {};            
            for j = 1:NumberOfTableDimensions
                Breakpoints{j} = {};
                for i=1:numel(BreakpointsForDimension{j})
                    Breakpoints{j}{i} = VarIdExpr(...
                        sprintf('%s_Breakpoints_dim%d_%d',blk_name,j,i));
                    %vars = sprintf('%s\t%s:%s;\n',vars,Breakpoints{j}{i},lusInport_dt);
                    vars{end+1} = LustreVar(Breakpoints{j}{i},lusInport_dt);
                    if ~isLookupTableDynamic
                        %body = sprintf('%s\t%s = %.15f ;\n', body, Breakpoints{j}{i}, BreakpointsForDimension{j}(i));
                        body{end+1} = LustreEq(Breakpoints{j}{i}, RealExpr(BreakpointsForDimension{j}(i)));
                    else
                        %body = sprintf('%s\t%s = %s;\n', body, Breakpoints{j}{i}, inputs{2}{i});
                        body{end+1} = LustreEq(Breakpoints{j}{i}, inputs{2}{i});
                    end
                    
                end
            end
        end
        
        function node_header = getNodeCodeHeader(isLookupTableDynamic,inputs,outputs,ext_node_name)
            
            if ~isLookupTableDynamic
                node_inputs = cell(1, numel(inputs));
                for i=1:numel(inputs)
                    node_inputs{i} = LustreVar(inputs{i}{1}, 'real');
                end
            else
                node_inputs{1} = LustreVar(inputs{1}{1}, 'real');
                for i=2:3
                    for j=1:numel(inputs{i})
                        node_inputs{end+1} = LustreVar(inputs{i}{j}, 'real');
                    end
                end
            end
            node_header.NodeName = ext_node_name;
            node_header.Inputs = node_inputs;
            node_header.Outputs = LustreVar(outputs{1}, 'real');
        end
        
        function codes = getMainCode(outputs,inputs,ext_node_name,isLookupTableDynamic)
            codes = cell(1, numel(outputs));
            for outIdx=1:numel(outputs)
                nodeCall_inputs = {};
                if isLookupTableDynamic
                    nodeCall_inputs{end+1} = inputs{1}{outIdx};
                    for i=2:numel(inputs)
                        nodeCall_inputs = [nodeCall_inputs, inputs{i}];
                    end
                else
                    nodeCall_inputs = cell(1, numel(inputs));
                    for i=1:numel(inputs)
                        nodeCall_inputs{i} = inputs{i}{outIdx};
                    end
                end
                
                codes{outIdx} = LustreEq(outputs{outIdx}, ...
                    NodeCallExpr(ext_node_name, nodeCall_inputs));
            end
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
        
        function blkParams = readBlkParams(parent,blk,isLookupTableDynamic,inputs)
            
            blkParams = struct;
            blkParams.BreakpointsForDimension = {};
            blkParams.skipInterpolation = 0;
            blkParams.yIsBounded = 0;
            
            if ~isLookupTableDynamic
                if strcmp(blk.DataSpecification, 'Lookup table object')
                    display_msg(sprintf('Lookup table object fir DataSpecification in block %s is not supported',...
                        blk.Origin_path), ...
                        MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
                end
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
            if ~isLookupTableDynamic
                blkParams.tableMin = min(blkParams.Table(:));
                blkParams.tableMax = max(blkParams.Table(:));
            end
        end
        
        function contractBody = getContractBody(blkParams,inputs,outputs)
            contractBody = {};
            % y is bounded when there is no extrapolation
            if blkParams.yIsBounded
                contractBody{end+1} = ContractGuaranteeExpr('', ...
                    BinaryExpr(BinaryExpr.AND, ...
                               BinaryExpr(BinaryExpr.GTE, ...
                                            outputs{1},...
                                            RealExpr(blkParams.tableMin)), ...
                                BinaryExpr(BinaryExpr.LTE, ...
                                            outputs{1},...
                                            RealExpr(blkParams.tableMax))));
                %sprintf('guarantee  %s >= %.15f and %s <= %.15f;',outputs{1},blkParams.tableMin, outputs{1},blkParams.tableMax);
            else
                % if u is inside boundary polytop, then y is also
                % bounded by table min and max
                %code = {};
                terms = cell(1,2*numel(inputs));
                counter = 0;
                for i=1:numel(inputs)
                    counter = counter + 1;
                    terms{counter} = BinaryExpr(BinaryExpr.GTE, ...
                                            inputs{i}{1},...
                                            RealExpr(min(blkParams.BreakpointsForDimension{i})));
                    counter = counter + 1;
                    terms{counter} = BinaryExpr(BinaryExpr.LTE, ...
                                            inputs{i}{1},...
                                            RealExpr(max(blkParams.BreakpointsForDimension{i})));
                    % code{end + 1} = sprintf('%s >= %.15f',inputs{i}{1},min(blkParams.BreakpointsForDimension{i}));
                    % code{end + 1} = sprintf('%s <= %.15f',inputs{i}{1},max(blkParams.BreakpointsForDimension{i}));
                end
                %P = MatlabUtils.strjoin(code, ' and ');
                P = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND,terms);
                %Q = sprintf('%s >= %.15f and  %s <= %.15f', outputs{1},blkParams.tableMin, outputs{1},blkParams.tableMax);
                Q = BinaryExpr(BinaryExpr.AND,...
                               BinaryExpr(BinaryExpr.GTE, ...
                                          outputs{1},...
                                          RealExpr(blkParams.tableMin)),...
                               BinaryExpr(BinaryExpr.LTE, ...
                                          outputs{1},...
                                          RealExpr(blkParams.tableMax)));
                contractBody{end+1} = ContractGuaranteeExpr('', ...
                    BinaryExpr(BinaryExpr.IMPLIES,...
                               P,...
                               Q));
                %sprintf('guarantee %s => %s;', P, Q);       check to see
                                                           % if using BinaryExpr.AND for "=>" is correct
            end
                       
            % contract for each element in total mesh
            if blkParams.NumberOfTableDimensions == 1
                for i=1:numel(blkParams.BreakpointsForDimension{1})-1
                    curTable = [];
                    curTable(1) = blkParams.Table(1,i);
                    curTable(2) = blkParams.Table(1,i+1);
                    P = BinaryExpr(BinaryExpr.AND,...
                                   BinaryExpr(BinaryExpr.GTE, ...
                                          inputs{1},...
                                          RealExpr(blkParams.BreakpointsForDimension{1}(i))),...
                                   BinaryExpr(BinaryExpr.LTE, ...
                                          inputs{1},...
                                          RealExpr(blkParams.BreakpointsForDimension{1}(i+1))));
                    Q = BinaryExpr(BinaryExpr.AND,...
                                   BinaryExpr(BinaryExpr.GTE, ...
                                          outputs{1},...
                                          RealExpr(min(curTable))),...
                                   BinaryExpr(BinaryExpr.LTE, ...
                                          outputs{1},...
                                          RealExpr(max(curTable))));
                    % code{end + 1} = sprintf('%s >= %.15f and %s <= %.15f',inputs{j}{1},blkParams.BreakpointsForDimension{1}(i),inputs{j}{1},blkParams.BreakpointsForDimension{1}(i+1));
                    %Q = sprintf('%s >= %.15f and  %s <= %.15f', outputs{1},min(curTable), outputs{1},max(curTable));
                    contractBody{end+1} = ContractGuaranteeExpr('', ...
                        BinaryExpr(BinaryExpr.IMPLIES,...
                                   P,...
                                   Q));
                    %contractBody{end+1} = sprintf('guarantee %s => %s;', P, Q);
                end
            elseif blkParams.NumberOfTableDimensions == 2
                for i=1:numel(blkParams.BreakpointsForDimension{1})-1
                    for j=1:numel(blkParams.BreakpointsForDimension{2})-1
                        curTable = [];
                        curTable(1) = blkParams.Table(i,j);
                        curTable(2) = blkParams.Table(i,j+1);
                        curTable(3) = blkParams.Table(i+1,j);
                        curTable(4) = blkParams.Table(i+1,j+1);     
                        P1_1 = BinaryExpr(BinaryExpr.GTE, ...
                                          inputs{1}{1},...
                                          RealExpr(blkParams.BreakpointsForDimension{1}(i)));   % dim 1 lower
                        P1_2 =   BinaryExpr(BinaryExpr.LTE, ...
                                            inputs{1}{1},...
                                            RealExpr(blkParams.BreakpointsForDimension{1}(i+1)));   % dim 1 upper                 
                        P2_1 = BinaryExpr(BinaryExpr.GTE, ...
                                          inputs{2}{1},...
                                          RealExpr(blkParams.BreakpointsForDimension{2}(j))); % dim 2 lower
                        P2_2 = BinaryExpr(BinaryExpr.LTE, ...
                                          inputs{2}{1},...
                                          RealExpr(blkParams.BreakpointsForDimension{2}(j+1)));   %dim 2 upper                      
                        
                        %code{end + 1} = sprintf('%s >= %.15f and %s <= %.15f',inputs{1}{1},blkParams.BreakpointsForDimension{1}(i),inputs{1}{1},blkParams.BreakpointsForDimension{1}(i+1));
                        %code{end + 1} = sprintf('%s >= %.15f and %s <= %.15f',inputs{2}{1},blkParams.BreakpointsForDimension{2}(j),inputs{2}{1},blkParams.BreakpointsForDimension{2}(j+1));
                        P = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND,{P1_1, P1_2, P2_1, P2_2});
                        Q = BinaryExpr(BinaryExpr.AND,...
                                       BinaryExpr(BinaryExpr.GTE, ...
                                              outputs{1},...
                                              RealExpr(min(curTable))),...
                                       BinaryExpr(BinaryExpr.LTE, ...
                                              outputs{1},...
                                              RealExpr(max(curTable))));
                        %Q = sprintf('%s >= %.15f and  %s <= %.15f', outputs{1},min(curTable), outputs{1},max(curTable));
                        contractBody{end+1} = ContractGuaranteeExpr('', ...
                            BinaryExpr(BinaryExpr.IMPLIES,...
                                       P,...
                                       Q));
                        %contractBody{end+1} = sprintf('guarantee %s => %s;', P, Q);
                    end
                end
            elseif blkParams.NumberOfTableDimensions == 3
                curTable = [];
                terms = {};
                for i=1:numel(blkParams.BreakpointsForDimension{1})-1
                    for j=1:numel(blkParams.BreakpointsForDimension{2})-1
                        for k=1:numel(blkParams.BreakpointsForDimension{3})-1
                            curTable = [];
                            curTable(1) = blkParams.Table(i,j,k);
                            curTable(2) = blkParams.Table(i,j+1,k);
                            curTable(3) = blkParams.Table(i+1,j,k);
                            curTable(4) = blkParams.Table(i+1,j+1,k);
                            curTable(5) = blkParams.Table(i,j,k+1);
                            curTable(6) = blkParams.Table(i,j+1,k+1);
                            curTable(7) = blkParams.Table(i+1,j,k+1);
                            curTable(8) = blkParams.Table(i+1,j+1,k+1);                            

                            P1_1 = BinaryExpr(BinaryExpr.GTE, ...
                                inputs{1}{1},...
                                RealExpr(blkParams.BreakpointsForDimension{1}(i)));   % dim 1 lower
                            P1_2 =   BinaryExpr(BinaryExpr.LTE, ...
                                inputs{1}{1},...
                                RealExpr(blkParams.BreakpointsForDimension{1}(i+1)));   % dim 1 upper
                            P2_1 = BinaryExpr(BinaryExpr.GTE, ...
                                inputs{2}{1},...
                                RealExpr(blkParams.BreakpointsForDimension{2}(j))); % dim 2 lower
                            P2_2 = BinaryExpr(BinaryExpr.LTE, ...
                                inputs{2}{1},...
                                RealExpr(blkParams.BreakpointsForDimension{2}(j+1)));   %dim 2 upper
                            P3_1 = BinaryExpr(BinaryExpr.GTE, ...
                                inputs{3}{1},...
                                RealExpr(blkParams.BreakpointsForDimension{3}(k))); % dim 3 lower
                            P3_2 = BinaryExpr(BinaryExpr.LTE, ...
                                inputs{3}{1},...
                                RealExpr(blkParams.BreakpointsForDimension{3}(k+1)));   %dim 3 upper                            
                            
                            P = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND,{P1_1, P1_2, P2_1, P2_2, P3_1, P3_2});
                            Q = BinaryExpr(BinaryExpr.AND,...
                                            BinaryExpr(BinaryExpr.GTE, ...
                                                        outputs{1},...
                                                        RealExpr(min(curTable))),...
                                            BinaryExpr(BinaryExpr.LTE, ...
                                                        outputs{1},...
                                                        RealExpr(max(curTable))));
                            contractBody{end+1} = ContractGuaranteeExpr('', ...
                                BinaryExpr(BinaryExpr.IMPLIES,...
                                P,...
                                Q));
                        end
                    end
                end                
            else
                display_msg(sprintf('More than 3 dimensions is not supported for contract in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
            end
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
        
        function [inputs,lusInport_dt,zero,one, external_lib] = ...
                getBlockInputsNames_convInType2AccType(parent, blk,isLookupTableDynamic)
            widths = blk.CompiledPortWidths.Inport;
            RndMeth = blk.RndMeth;
            max_width = max(widths);
            external_lib = '';
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
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
        end
        
        function y_interp = interp2points_2D(x1, y1, x2, y2, x_interp)
            % This function perform linear interpolation/extrapolation for
            % 2D from 2 points (x1,y1) and (x2, y2).
            % All parameters need to be LustreAst objects
            b1 = BinaryExpr(BinaryExpr.MINUS,x2,x_interp); 
            b2 = BinaryExpr(BinaryExpr.MINUS,x_interp,x1); 
            n1 = BinaryExpr(BinaryExpr.MULTIPLY,y1,b1);
            n2 = BinaryExpr(BinaryExpr.MULTIPLY,y2,b2);
            num = BinaryExpr(BinaryExpr.PLUS,n1,n2);
            denum = BinaryExpr(BinaryExpr.MINUS,x2,x1);            
            y_interp = BinaryExpr(BinaryExpr.DIVIDE, num, denum);
        end
    end
    
end

