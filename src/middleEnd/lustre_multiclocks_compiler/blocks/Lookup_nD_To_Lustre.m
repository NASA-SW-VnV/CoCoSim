classdef Lookup_nD_To_Lustre < Block_To_Lustre
    % Selector_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            inputs = {};
            
            widths = blk.CompiledPortWidths.Inport;
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            RndMeth = blk.RndMeth;
            
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                [lusInport_dt, zero, one] = SLX2LusUtils.get_lustre_dt(inport_dt);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType) && i <= 2
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType,RndMeth);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            
            % initialize
            addVarIndex = 0;
            codeIndex = 0;
            codes = {};            
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk);  
            BreakpointsForDimension = {}
            
            % read blk
            [NumberOfTableDimensions, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfTableDimensions);
            for i=1:NumberOfTableDimensions
                evalString = sprintf('[BreakpointsForDimension{i}, ~, ~] = Constant_To_Lustre.getValueFromParameter(parent, blk, blk.BreakpointsForDimension%d); ',i);
                eval(evalString);
            end
           
            [Table, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Table);                     
            InterpMethod = blk.InterpMethod;
            ExtrapMethod = blk.ExtrapMethod;
            skipInterpolation = 0;            
            if strcmp(InterpMethod,'Flat') || strcmp(InterpMethod,'Nearest')
                skipInterpolation = 1;                
            end            
            
            % UseOneInputPortForAllInputData
            p_inputs = {};
            if strcmp(blk.UseOneInputPortForAllInputData, 'on')
                dimLen = numel(inputs{1})/NumberOfTableDimensions;
                for i=1:NumberOfTableDimensions
                    p_inputs{i} = inputs{1}((i-1)*dimLen+1:i*dimLen);
                end
            else
                p_inputs = inputs;
            end            
            
            % declaring and defining table 
            table_elem = {}
            for i=1:numel(Table)
                    table_elem{i} = sprintf('%s_table_elem_%d',SLX2LusUtils.name_format(blk.Name),i);
                    addVarIndex = addVarIndex + 1;
                    addVars{addVarIndex} = sprintf('%s:%s;',table_elem{i},lusInport_dt);
                    codeIndex = codeIndex + 1;
                    codes{codeIndex} = sprintf('%s = %f ;\n\t', table_elem{i}, Table(i));
            end
            % declaring and defining break points            
            for j = 1:NumberOfTableDimensions
                Breakpoints{j} = {}
                for i=1:numel(BreakpointsForDimension{j})
                    Breakpoints{j}{i} = sprintf('%s_Breakpoints_dim%d_%d',SLX2LusUtils.name_format(blk.Name),j,i);
                    addVarIndex = addVarIndex + 1;
                    addVars{addVarIndex} = sprintf('%s:%s;',Breakpoints{j}{i},lusInport_dt);      
                    codeIndex = codeIndex + 1;
                    codes{codeIndex} = sprintf('%s = %f ;\n\t', Breakpoints{j}{i}, BreakpointsForDimension{j}(i));                    
                end
            end
            
            % shape functions interpolation
            numGridPoints = 2^NumberOfTableDimensions;
            indexDataType = 'int';
            
            % defining nodes bounding element (coords_node{NumberOfTableDimensions,2}: dim1_low, dim1_high,
            % dim2_low, dim2_high,... dimn_low, dimn_high)
                        
            % finding nodes bounding element
            coords_node = {};  
            index_node = {};  
            boundingNodes = zeros(NumberOfTableDimensions,2);
            for i=1:NumberOfTableDimensions
                % low node for dimension i
                coords_node{i,1} = sprintf('%s_coords_dim_%d_1',SLX2LusUtils.name_format(blk.Name),i);
                addVarIndex = addVarIndex + 1;
                addVars{addVarIndex} = sprintf('%s:%s;',coords_node{i,1},lusInport_dt);
                
                index_node{i,1} = sprintf('%s_index_dim_%d_1',SLX2LusUtils.name_format(blk.Name),i);
                addVarIndex = addVarIndex + 1;
                addVars{addVarIndex} = sprintf('%s:%s;',index_node{i,1},indexDataType);                
                
                % high node for dimension i
                coords_node{i,2} = sprintf('%s_coords_dim_%d_2',SLX2LusUtils.name_format(blk.Name),i);
                addVarIndex = addVarIndex + 1;
                addVars{addVarIndex} = sprintf('%s:%s;',coords_node{i,2},lusInport_dt);
                
                index_node{i,2} = sprintf('%s_index_dim_%d_2',SLX2LusUtils.name_format(blk.Name),i);
                addVarIndex = addVarIndex + 1;
                addVars{addVarIndex} = sprintf('%s:%s;',index_node{i,2},indexDataType);                  
                
                % looking for low node                
                code = sprintf('%s = \n\t', coords_node{i,1});    % code for coordinate values
                index_code = sprintf('%s = \n\t', index_node{i,1});  % index_code for indices
                for j=numel(BreakpointsForDimension{i}):-1:1
                    if j==numel(BreakpointsForDimension{i})
                        if ~skipInterpolation
                            % for extrapolation, we want to use the last 2
                            % nodes
                            code = sprintf('%s  if(%s >= %s) then %s\n\t', code, p_inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j-1});
                            index_code = sprintf('%s  if(%s >= %s) then %d\n\t', index_code, p_inputs{i}{1},Breakpoints{i}{j},(j-1));
                        else
                            % for "flat" we want lower node to be last node
                            code = sprintf('%s  if(%s >= %s) then %s\n\t', code, p_inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
                            index_code = sprintf('%s  if(%s >= %s) then %d\n\t', index_code, p_inputs{i}{1},Breakpoints{i}{j},(j));
                        end
                        
                    else
                        code = sprintf('%s  else if(%s >= %s) then %s\n\t', code, p_inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
                        index_code = sprintf('%s  else if(%s >= %s) then %d\n\t', index_code, p_inputs{i}{1},Breakpoints{i}{j},j);
                    end

                end
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s  else %d ;\n\t', index_code,1);
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,Breakpoints{i}{1});
                % looking for high node
                code = sprintf('%s = \n\t', coords_node{i,2});
                index_code = sprintf('%s = \n\t', index_node{i,2});
                for j=numel(BreakpointsForDimension{i}):-1:1
                    if j==numel(BreakpointsForDimension{i})
                        code = sprintf('%s  if(%s >= %s) then %s\n\t', code, p_inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
                        index_code = sprintf('%s  if(%s >= %s) then %d\n\t', index_code, p_inputs{i}{1},Breakpoints{i}{j},j);
                    else
                        code = sprintf('%s  else if(%s >= %s) then %s\n\t', code, p_inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j+1});
                        index_code = sprintf('%s  else if(%s >= %s) then %d\n\t', index_code, p_inputs{i}{1},Breakpoints{i}{j},(j+1));
                    end                  
                end
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s  else %d ;\n\t', index_code,2);
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,Breakpoints{i}{2});
                
            end
            
            % if flat, make inputs the lowest bounding node
            returnTableIndex = {};            
            u_node = {};
            N_shape_node = {};
            
            % declaring node value and shape function
            if ~skipInterpolation
                for i=1:numGridPoints
                    % y results at the node of the element
                    u_node{i} = sprintf('%s_u_node_%d',SLX2LusUtils.name_format(blk.Name),i);
                    addVarIndex = addVarIndex + 1;
                    addVars{addVarIndex} = sprintf('%s:%s;',u_node{i},lusInport_dt);
                    % shape function result at the node of the element
                    N_shape_node{i} = sprintf('%s_N_shape_%d',SLX2LusUtils.name_format(blk.Name),i);
                    addVarIndex = addVarIndex + 1;
                    addVars{addVarIndex} = sprintf('%s:%s;',N_shape_node{i},lusInport_dt);
                end
            end
            
            % defining u
            
            % doing subscripts to index in Lustre.  Need subscripts, and
            % dimension jump.  
            % calculating dimension jump
            shapeNodeSign = Lookup_nD_To_Lustre.getShapeBoundingNodeSign(NumberOfTableDimensions);
            dimJump = ones(1,NumberOfTableDimensions);
            L_dimjump = {};
            L_dimjump{1} =  sprintf('%s_dimJump_%d',SLX2LusUtils.name_format(blk.Name),1);
            addVarIndex = addVarIndex + 1;
            addVars{addVarIndex} = sprintf('%s:%s;',L_dimjump{1},indexDataType);
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %d;\n\t', L_dimjump{1}, dimJump(1));
            for i=2:NumberOfTableDimensions
                L_dimjump{i} =  sprintf('%s_dimJump_%d',SLX2LusUtils.name_format(blk.Name),i);
                addVarIndex = addVarIndex + 1;
                addVars{addVarIndex} = sprintf('%s:%s;',L_dimjump{i},indexDataType);
                for j=1:i-1
                    dimJump(i) = dimJump(i)*numel(BreakpointsForDimension{j});
                end
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s = %d;\n\t', L_dimjump{i}, dimJump(i));                   
            end
            
            boundingNodeIndex = {};
            nodeIndex = 0;
            for i=1:numGridPoints
                nodeIndex= nodeIndex+1;
                dimSign = shapeNodeSign(nodeIndex,:);  
                
                % declaring boundingNodeIndex{nodeIndex}
                boundingNodeIndex{nodeIndex} = sprintf('%s_bound_node_index_%d',SLX2LusUtils.name_format(blk.Name),nodeIndex);
                addVarIndex = addVarIndex + 1;
                addVars{addVarIndex} = sprintf('%s:%s;',boundingNodeIndex{nodeIndex},indexDataType);

                % defining boundingNodeIndex{nodeIndex}
                value = '0';
                for j=1:NumberOfTableDimensions
                    % dimSign(j): -1 is low, 1: high
                    if dimSign(j) == -1
                        curIndex =  index_node{j,1};
                    else
                        curIndex =  index_node{j,2}
                    end
                    if j==1
                        value = sprintf('%s + %s*%d',value,curIndex, dimJump(j))
                    else
                        value = sprintf('%s + (%s-1)*%d',value,curIndex, dimJump(j))
                    end
                end
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s = %s;\n\t', boundingNodeIndex{nodeIndex}, value)
                                
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
                    codeIndex = codeIndex + 1;
                    codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,table_elem{numel(table_elem)});
                end

            end   
                       
            if skipInterpolation
            
                returnTableIndex{1} =  sprintf('%s_retTableInd_%d',SLX2LusUtils.name_format(blk.Name),1);
                addVarIndex = addVarIndex + 1;
                addVars{addVarIndex} = sprintf('%s:%s;',returnTableIndex{1},indexDataType);
                
                if strcmp(InterpMethod,'Flat')
                    % defining returnTableIndex{1}
                    value = '0';
                    for j=1:NumberOfTableDimensions
                        
                        curIndex =  index_node{j,1};
                        if j==1
                            value = sprintf('%s + %s*%d',value,curIndex, dimJump(j))
                        else
                            value = sprintf('%s + (%s-1)*%d',value,curIndex, dimJump(j))
                        end
                    end
                else   % 'Nearest' case
                    % defining returnTableIndex{1}
                    disFromTableNode = {};
                    nearestIndex = {};
                    for i=1:NumberOfTableDimensions                        
                        disFromTableNode{i,1} = sprintf('%s_disFromTableNode_dim_%d_1',SLX2LusUtils.name_format(blk.Name),i);
                        addVarIndex = addVarIndex + 1;
                        addVars{addVarIndex} = sprintf('%s:%s;',disFromTableNode{i,1},lusInport_dt);
                        disFromTableNode{i,2} = sprintf('%s_disFromTableNode_dim_%d_2',SLX2LusUtils.name_format(blk.Name),i);
                        addVarIndex = addVarIndex + 1;
                        addVars{addVarIndex} = sprintf('%s:%s;',disFromTableNode{i,2},lusInport_dt);
                        codeIndex = codeIndex + 1;
                        codes{codeIndex} = sprintf('%s = %s - %s ;\n\t', disFromTableNode{i,1},p_inputs{i}{1},coords_node{i,1});                        
                        codeIndex = codeIndex + 1;
                        codes{codeIndex} = sprintf('%s = %s - %s ;\n\t', disFromTableNode{i,2},coords_node{i,2},p_inputs{i}{1});
                        
                        nearestIndex{i} = sprintf('%s_nearestIndex_dim_%d',SLX2LusUtils.name_format(blk.Name),i);
                        addVarIndex = addVarIndex + 1;
                        addVars{addVarIndex} = sprintf('%s:%s;',nearestIndex{i},indexDataType);                            

                        code = sprintf('%s = if(%s <= %s) then %s\n\t', nearestIndex{i},disFromTableNode{i,2},disFromTableNode{i,1},index_node{i,2});
                        codeIndex = codeIndex + 1;
                        codes{codeIndex} = sprintf('%s  else %s;\n\t', code, index_node{i,1});
                    end
                         
                    value = '0';
                    for j=1:NumberOfTableDimensions   
                        if j==1
                            value = sprintf('%s + %s*%d',value,nearestIndex{j}, dimJump(j))
                        else
                            value = sprintf('%s + (%s-1)*%d',value,nearestIndex{j}, dimJump(j))
                        end
                    end
                end
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s = %s;\n\t', returnTableIndex{1}, value)
                % defining outputs{1}
                code = sprintf('%s = \n\t', outputs{1});
                for j=1:numel(table_elem)-1
                    if j==1
                        code = sprintf('%s  if(%s = %d) then %s\n\t', code, returnTableIndex{1},j,table_elem{j});
                    else
                        code = sprintf('%s  else if(%s = %d) then %s\n\t', code, returnTableIndex{1},j,table_elem{j});
                    end
                end
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,table_elem{numel(table_elem)});
 
            else
                if strcmp(InterpMethod,'Linear')
                    % calculating linear shape function value
                    denom = one;
                    for i=1:NumberOfTableDimensions
                        denom = sprintf('%s*(%s-%s)',denom,coords_node{i,2},coords_node{i,1});
                    end
                    denom = sprintf('(%s)',denom);
                    
                    for i=1:numGridPoints
                        code = one;
                        for j=1:NumberOfTableDimensions
                            if shapeNodeSign(i,j)==-1
                                code = sprintf('%s*(%s-%s)',code,coords_node{j,2},p_inputs{j}{1});
                            else
                                code = sprintf('%s*(%s-%s)',code,p_inputs{j}{1},coords_node{j,1});
                            end
                        end
                        codeIndex = codeIndex + 1;
                        codes{codeIndex} = sprintf('%s = (%s)/%s ;\n\t', N_shape_node{i}, code,denom);
                    end
                else  % Cubic spline
                     denom = one;
                    for i=1:NumberOfTableDimensions
                        denom = sprintf('%s*(%s-%s)',denom,coords_node{i,2},coords_node{i,1});
                    end
                    
                    for i=1:numGridPoints
                        code = one;
                        for j=1:NumberOfTableDimensions
                            if shapeNodeSign(i,j)==-1
                                code = sprintf('%s*(%s-%s)',code,coords_node{j,2},p_inputs{j}{1});
                            else
                                code = sprintf('%s*(%s-%s)',code,p_inputs{j}{1},coords_node{j,1});
                            end
                        end
                        codeIndex = codeIndex + 1;
                        codes{codeIndex} = sprintf('%s = (%s)/%s ;\n\t', N_shape_node{i}, code,denom);
                    end                   
                end
                
                code = zero;
                for i=1:numGridPoints
                    code = sprintf('%s+%s*%s ',code,N_shape_node{i},u_node{i});
                end
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s = %s ;\n\t', outputs{1}, code);
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
            obj.addVariable(addVars);
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};
            [NumberOfTableDimensions, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfTableDimensions);
            if NumberOfTableDimensions >= 7
                obj.unsupported_options{numel(obj.unsupported_options) + 1} = ...
                    sprintf('More than 7 dimensions is not support in block %s', blk.Origin_path);
            end 
            if ~strcmp(blk.InterpMethod, 'Cubic spline')
                obj.unsupported_options{numel(obj.unsupported_options) + 1} = ...
                    sprintf('Cubic spline interpolation is not support in block %s', blk.Origin_path);
            end            
            options = obj.unsupported_options;
        end
    end
    
    methods(Static)
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
    end
        
end

