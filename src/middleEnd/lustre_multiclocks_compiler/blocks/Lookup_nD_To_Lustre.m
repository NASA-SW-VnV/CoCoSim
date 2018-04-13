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
            
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                [lusInport_dt, zero, one] = SLX2LusUtils.get_lustre_dt(inport_dt);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType) && i <= 2
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
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
            
            RndMeth = blk.RndMeth;
            
            % storing table
            table_elem = {}
            for i=1:numel(Table)
                    table_elem{i} = sprintf('%s_table_elem_%d',SLX2LusUtils.name_format(blk.Name),i);
                    addVarIndex = addVarIndex + 1;
                    addVars{addVarIndex} = sprintf('%s:%s;',table_elem{i},lusInport_dt);
                    codeIndex = codeIndex + 1;
                    codes{codeIndex} = sprintf('%s = %f ;\n\t', table_elem{i}, Table(i));
            end
            % storing break points
            
            for j = 1:NumberOfTableDimensions
                Breakpoints{j} = {}
                for i=1:numel(BreakpointsForDimension)
                    Breakpoints{j}{i} = sprintf('%s_Breakpoints_dim%d_%d',SLX2LusUtils.name_format(blk.Name),j,i);
                    addVarIndex = addVarIndex + 1;
                    addVars{addVarIndex} = sprintf('%s:%s;',Breakpoints{j}{i},lusInport_dt);      
                    codeIndex = codeIndex + 1;
                    codes{codeIndex} = sprintf('%s = %f ;\n\t', Breakpoints{j}{i}, BreakpointsForDimension{j}(i));                    
                end
            end
            % shape functions interpolation
            numGridPoints = 2^NumberOfTableDimensions;
            u_node = {};
            N_shape_node = {};
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
            
            % defining u_node and N_shape_node
            
            
            % write function to find nodes bounding element
            coords_node = {};  % storing convention:  dim1_low, dim1_high, dim2_low, dim2_high,... dimn_low, dimn_high
            for i=1:NumberOfTableDimensions
                % low                   
                coords_node{i,1} = sprintf('%s_coords_dim_%d_1',SLX2LusUtils.name_format(blk.Name),i);
                addVarIndex = addVarIndex + 1;
                addVars{addVarIndex} = sprintf('%s:%s;',coords_node{i,1},lusInport_dt);
%                 codeIndex = codeIndex + 1;
%                 code = sprintf('%s = \n\t', coords_node{i,1});                
%                 for j=(numel(Breakpoints{i})-0):-1:1
%                         if j==numel(numel(Breakpoints{i})-1)
%                             code = sprintf('%s  if(%s < %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j-1});
%                         else
%                             code = sprintf('%s  else if(%s = %d) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j-1});
%                         end                
%                 end
%                 codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,Breakpoints{i}{numel(Breakpoints{i})});
                % high                
                coords_node{i,2} = sprintf('%s_coords_dim_%d_2',SLX2LusUtils.name_format(blk.Name),i);
                addVarIndex = addVarIndex + 1;
                addVars{addVarIndex} = sprintf('%s:%s;',coords_node{i,2},lusInport_dt);
%                 codeIndex = codeIndex + 1;
%                 code = sprintf('%s = \n\t', coords_node{i,2});                
%                 for j=(numel(Breakpoints{i})-0):-1:1
%                     if j==numel(numel(Breakpoints{i})-1)
%                         code = sprintf('%s  if(%s < %s) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
%                     else
%                         code = sprintf('%s  else if(%s = %d) then %s\n\t', code, inputs{i}{1},Breakpoints{i}{j},Breakpoints{i}{j});
%                     end
%                 end
%                 codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,Breakpoints{i}{numel(Breakpoints{i})});
            end
            
            
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', coords_node{1,1}, Breakpoints{1}{1});
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', coords_node{1,2}, Breakpoints{1}{2});
            codeIndex = codeIndex + 1;
            
            codes{codeIndex} = sprintf('%s = %s ;\n\t', coords_node{2,1}, Breakpoints{2}{1});
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', coords_node{2,2}, Breakpoints{2}{2});
            

%             % defining u
%             nodeIndex = 0;
%             for i=1:NumberOfTableDimensions
%                 % low     
%                 nodeIndex= nodeIndex+1;
%                 codeIndex = codeIndex + 1;
%                 code = sprintf('%s = \n\t', u_node{nodeIndex});                
%                 for j=(numel(Breakpoints{i})-1):-1:1
%                         if j==numel(numel(Breakpoints{i})-1)
%                             code = sprintf('%s  if(%s >= %s) then %s\n\t', code, inputs{i},Breakpoints{i}{j},table_elem{i}{i}(j));
%                         else
%                             code = sprintf('%s  else if(%s = %d) then %s\n\t', code, inputs{i},Breakpoints{i}{j},table_elem{i}{i}(j));
%                         end                
%                 end
%                 codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,table_elem{i}{i}(1));
%                 % high
% 
%                 nodeIndex= nodeIndex+1;
%                 codeIndex = codeIndex + 1;
%                 code = sprintf('%s = \n\t', u_node{nodeIndex});            
%                 for j=(numel(Breakpoints{i})-1):-1:1
%                     if j==numel(numel(Breakpoints{i})-1)
%                         code = sprintf('%s  if(%s >= %s) then %s\n\t', code, inputs{i},Breakpoints{i}{j},table_elem{i}{i}{j+1});
%                     else
%                         code = sprintf('%s  else if(%s = %d) then %s\n\t', code, inputs{i},Breakpoints{i}{j},table_elem{i}{i}{j+1});
%                     end
%                 end
%                 codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,table_elem{i}{i}(1+1));
%             end            
            
            % write function to define shape function value

            code = one;
            % N1
            for j=1:NumberOfTableDimensions
                code = sprintf('%s*((%s-%s)/(%s-%s))',code,coords_node{j,2},inputs{j}{1},coords_node{j,2},coords_node{j,1});
            end
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', N_shape_node{1}, code);
          
            % N2
            code = one;
            for j=1:NumberOfTableDimensions
                code = sprintf('%s*((%s-%s)/(%s-%s))',code,coords_node{j,2},inputs{j}{1},coords_node{j,2},coords_node{j,1});
            end
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', N_shape_node{2}, code);            
            
            % N3
            code = one;
            for j=1:NumberOfTableDimensions
                code = sprintf('%s*((%s-%s)/(%s-%s))',code,coords_node{j,2},inputs{j}{1},coords_node{j,2},coords_node{j,1});
            end
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', N_shape_node{3}, code);       
            
            % N4
            code = one;
            for j=1:NumberOfTableDimensions
                code = sprintf('%s*((%s-%s)/(%s-%s))',code,coords_node{j,2},inputs{j}{1},coords_node{j,2},coords_node{j,1});
            end
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', N_shape_node{4}, code);               
            
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', u_node{1}, table_elem{1});
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', u_node{2}, table_elem{2});
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', u_node{3}, table_elem{3});
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', u_node{4}, table_elem{4});                      
            
            code = zero;
            for i=1:numGridPoints            
                code = sprintf('%s+%s*%s ',code,N_shape_node{i},u_node{i});               
            end
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s ;\n\t', outputs{1}, code);
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
            obj.addVariable(addVars);
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};
 
            
            options = obj.unsupported_options;
        end
    end
        
end

