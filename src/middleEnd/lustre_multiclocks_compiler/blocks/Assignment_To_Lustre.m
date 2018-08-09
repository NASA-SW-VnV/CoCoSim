classdef Assignment_To_Lustre < Block_To_Lustre
    % Assignment_To_Lustre
    % Y0, U and Y (inputs{1}, inputs{2} and outputs respestively) are
    % inline.  In writing the Lustre code, we loop over the inline outputs.
    %  For each index, we check the U_to_Y0 to see if for this index the
    %  value of Y should be assigned the corresponding index value in Y0 or
    %  a value in U.  If a value in U is to be used, then the U_to_Y0 map
    %  will tell us which index of U to use.
    % Key to this task is understanding and using the mapping cell array
    % ind and the U_to_Y0 inline map. 
    %   ind{i} maps index for dimension i.  This is expanding out the user
    %   inputs from the dialog box
    %      -  ind{1} = [1,3] means for dimension 1, U has 2 rows (length of array), 1st row of U maps
    %      to 1st row of Y, 2nd row of U maps to 3rd row of Y
    %      -  for non "port" row i, ind{i} is an array of integer
    %      -  for "port" row i, ind{i} is an array of string for Lustre code
    %      -  when the input of U is a scalar but meant to be expanded to fill up
    %      the length of a dimension, expand U first so the
    %      definition of ind doesn't change.  
    %   U_to_Y0 maps the inline element of U that will replace the inline element
    %   in Y (or Y0).  For example if U_to_Y0 = [2, 4, 5] means inline Y(2)
    %   = inline U(1), inline Y(4) = inline U(2) and inline Y(5) = inline
    %   U(3).  For indices of Y that not in U_to_Y0, inline Y of
    %   those indices will be equal to corresponding Y0 values.  inline
    %   Y(1) = Y0(1), Y(3) = Y0(3), Y(6 and above) = Y0(6 and above).
    %   ind{i} maps are in matrix subscripts, inputs and outputs are inline. 
    %   The matlab function sub2ind and ind2sub are used to calculate U_to_Y0.
    %   Once we have U_to_Y0, we can loop through all inline outputs, for
    %   those output indices found in U_to_Y0, we assign them with the U
    %   index.  For those indices not found in U_to_Y0, we assign them with
    %   corresponding Y0.
    %
    % There are 2 different coding schemes.  If a dimension is not a port input,
    % the index assignment logic is done by Matlab and the array of that dimension are numeric. Key here
    % is the use of the matlab function ind2sub and sub2ind to convert from
    % matrix subscripts to inline indices.
    % If a dimension is a port
    % input, the logic is done by Lustre and the array of that dimension are string to be used in Lustre. 
    % The work of the matlab function ind2sub and sub2ind must be done on
    % the Lustre side.
    % 
    % Using dimJump to get inline index from subscritps of a multidimensional array
    %   index = '0';
    %   for j=1:numel(dims)      % looping through number of dimensions
    %       if j==1
    %          index = index + subscript(j)*dimJump(j);
    %       else
    %          index = index + (subscript(j)-1)*dimJump(j);
    %       end
    %   end
    %
    % Example (assignment_mixed_port_u_expanded.slx):
    % blk.CompiledPortDimensions =  "Inport": [2,3,2,1,1,1,1],
    %                              "Outport": [2,3,2]
    % blk.CompiledPortWidths = "Inport": [ 6, 1, 1 ], "Outport": 6
    % blk.IndexMode: "One-based",
    % blk.IndexOptionArray: ["Index vector (dialog)","Starting index (port)"],
    % blk.IndexOptions: "Index vector (dialog),Starting index (port)",
    % blk.IndexParamArray: ["[1 3]","2"],
    % blk.Indices: "[1 3],2",
    % blk.NumberOfDimensions: "2",
    % Lustre generated:
    %           -- Calculate first ind_dim which helps in converting matrix 
    %              subscripts to inline index.            
    % 	ind_dim_1_1 = 1;
    % 	ind_dim_1_2 = 3;
    % 	ind_dim_2_1 = real_to_int(Saturation_1);
    % 	str_Y_index_1_1 = ind_dim_1_1;
    % 	str_Y_index_1_2 = ind_dim_2_1;
    % 	U_index_1 = 0 + str_Y_index_1_1*1 + (str_Y_index_1_2-1)*3;
    % 	str_Y_index_2_1 = ind_dim_1_2;
    % 	str_Y_index_2_2 = ind_dim_2_1;
    % 	U_index_2 = 0 + str_Y_index_2_1*1 + (str_Y_index_2_2-1)*3;
    % 	Assignment_1 = 
    % 	  if(U_index_2 = 1) then Constant1_1
    % 	  else if(U_index_1 = 1) then Constant1_1
    % 	  else In1_1 ;
    % 	Assignment_2 = 
    % 	  if(U_index_2 = 2) then Constant1_1
    % 	  else if(U_index_1 = 2) then Constant1_1
    % 	  else In1_2 ;
    % 	Assignment_3 = 
    % 	  if(U_index_2 = 3) then Constant1_1
    % 	  else if(U_index_1 = 3) then Constant1_1
    % 	  else In1_3 ;
    % 	Assignment_4 = 
    % 	  if(U_index_2 = 4) then Constant1_1
    % 	  else if(U_index_1 = 4) then Constant1_1
    % 	  else In1_4 ;
    % 	Assignment_5 = 
    % 	  if(U_index_2 = 5) then Constant1_1
    % 	  else if(U_index_1 = 5) then Constant1_1
    % 	  else In1_5 ;
    % 	Assignment_6 = 
    % 	  if(U_index_2 = 6) then Constant1_1
    % 	  else if(U_index_1 = 6) then Constant1_1
    % 	  else In1_6 ;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
    properties
    end
    
    methods
              
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
            % share code with Selector_To_Lustre
            isSelector = 0;
            % getBlockInputsOutputs
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            % for the example above (assignment_mixed_port_u_expanded.slx): 
            % outputs = {{'Assignment_1'}    {'Assignment_2'}    {'Assignment_3'}    {'Assignment_4'}    {'Assignment_5'}  {'Assignment_6'}}
            % outputs_dt = {'Assignment_1: real;', 'Assignment_2: real;',
            %               'Assignment_3: real;','Assignment_4: real;', 'Assignment_5: real;',
            %               'Assignment_6: real;'}            
            
            [inputs] = ...
                Assignment_To_Lustre.getBlockInputsNames_convInType2AccType(obj, parent, blk,isSelector);
            % For the exmple above:
            % inputs{1} = 'In1_1'    'In1_2'    'In1_3'  'In1_4'    'In1_5'    'In1_6'
            % inputs{2} = 'Constant1_1'
            % inputs{3} = 'real_to_int(Saturation_1)'
   
            [numOutDims, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);   
            % For the example above
            % numOutDims = 2
            
            % get matrix dimension of all inputs, and expand U if needed.
            % inputs is also expanded if U is expanded
            % expanding second input            
            [in_matrix_dimension, U_expanded_dims,inputs] = ...
                obj.expand_U(parent,blk,inputs,numOutDims);
            % For the example above
            % in_matrix_dimension{1} =struct( "numDs": 2, "dims": [3,2], "width": 6)
            % in_matrix_dimension{2} =struct( "numDs": 1, "dims": 1, "width": 1)
            % in_matrix_dimension{3} =struct( "numDs": 1, "dims": 1, "width": 1)
            % U_expanded_dims = struct( "numDs": 2, "dims": [2,1], "width": 2) 
            % inputs{2} changed to
            % inputs{2} = 'Constant1_1'  'Constant1_1'
                
            % define mapping array ind
            isSelector = 0;
            [isPortIndex,ind,~] = Assignment_To_Lustre.defineMapInd(obj,parent,blk,inputs,U_expanded_dims,isSelector);
            % For the example above
            % isPortIndex = 1
            % ind{1} = [1,3]  
            % ind{2} = 'real_to_int(Saturation_1)' 
           
            % if index assignment is read in from index port, write mapping
            % code on Lustre side
            if isPortIndex
                [codes] = getWriteCodeForPortInput(obj, in_matrix_dimension,inputs,outputs,numOutDims,U_expanded_dims,ind,blk);                
            else  % no port input
                [codes] = getWriteCodeForNonPortInput(obj,in_matrix_dimension,inputs,outputs,U_expanded_dims,ind);                
            end
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            obj.unsupported_options = {};
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
            if in_matrix_dimension{1}.numDs>7
                msg = sprintf('More than 7 dimensions is not supported in block %s',...
                    blk.Origin_path);
                obj.addUnsupported_options(msg);
            end
            if isequal(blk.OutputInitialize, 'Specify size for each dimension in table')
                msg = sprintf('OutputInitialize Parameter in block %s is not supported. It should be set to "Initialize using input port <Y0>"',...
                    blk.Origin_path);
                obj.addUnsupported_options(msg);
            end
            
            for i=1:numel(blk.IndexOptionArray)
                if strcmp(blk.IndexOptionArray{i}, 'Starting and ending indices (port)')
                    msg = sprintf('IndexOption  %s not supported in block %s',...
                        blk.IndexOptionArray{i}, blk.Origin_path);
                    obj.addUnsupported_options(msg);
                end
            end
            options = obj.unsupported_options;
        end   
        
        function [in_matrix_dimension, U_expanded_dims,inputs] = ...
                expand_U(~, parent,blk,inputs,numOutDims)
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
            U_expanded_dims = in_matrix_dimension{2};
            % if U input is a scalar and it is to be expanded, U_expanded_dims
            % needed to be calculated.
            indexPortNumber = 0;
            if numel(inputs{2}) == 1
                U_expanded_dims.numDs = numOutDims;   
                U_expanded_dims.dims = ones(1,numOutDims);
                U_expanded_dims.width = 1;
                for i=1:numOutDims
                    if strcmp(blk.IndexOptionArray{i}, 'Assign all')
                        U_expanded_dims.dims(i) = in_matrix_dimension{1}.dims(i);
                    elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (dialog)')
                        U_expanded_dims.dims(i) = ...
                            numel(Constant_To_Lustre.getValueFromParameter(parent, blk,blk.IndexParamArray{i}));
                    elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (port)')
                        indexPortNumber = indexPortNumber + 1;
                        portNumber = indexPortNumber + 2;
                        U_expanded_dims.dims(i) = numel(inputs{portNumber});
                    elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (dialog)')
                        U_expanded_dims.dims(i) = 1;
                    elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                        U_expanded_dims.dims(i) = 1;
                    else
                    end
                    U_expanded_dims.width = U_expanded_dims.width*U_expanded_dims.dims(i);
                end
            end
            
            if numel(inputs{2}) == 1 && numel(inputs{2}) < U_expanded_dims.width
                inputs{2} = arrayfun(@(x) {inputs{2}{1}}, (1:U_expanded_dims.width));
            end             
        end        
        
        function [codes] = getWriteCodeForNonPortInput(~, in_matrix_dimension,inputs,outputs,U_expanded_dims,ind)
            %% function get code for noPortInput
            
            % initialization
                     
            if in_matrix_dimension{1}.numDs == 1   % for 1D
                U_to_Y0 = ind{1};
            else
                % support max dimensions = 7
                sub2ind_string = 'U_to_Y0 = sub2ind(in_matrix_dimension{1}.dims';
                dString = {'[ ', '[ ', '[ ', '[ ', '[ ', '[ ', '[ '};
                
                for i=1:numel(inputs{2})    % looping over U elements
                    [d1, d2, d3, d4, d5, d6, d7 ] = ind2sub(U_expanded_dims.dims,i);
                    d = [d1, d2, d3, d4, d5, d6, d7 ];
                    
                    for j=1:numel(in_matrix_dimension{1}.dims)
                        y0d(j) = ind{j}(d(j));
                        if i==1
                            dString{j}  = sprintf('%s%d', dString{j}, y0d(j));
                        else
                            dString{j}  = sprintf('%s, %d', dString{j}, y0d(j));
                        end
                    end
                end
                
                for j=1:numel(in_matrix_dimension{1}.dims)
                    sub2ind_string = sprintf('%s, %s]',sub2ind_string,dString{j});
                end
                sub2ind_string = sprintf('%s);',sub2ind_string);
                eval(sub2ind_string);
            end
            
            % U_to_Y0 should be defined at this point
            codes = cell(1, numel(outputs));  
            for i=1:numel(outputs)
                if find(U_to_Y0==i)
                    Uindex = find(U_to_Y0==i);
                    codes{i} = LustreEq(outputs{i}, inputs{2}{Uindex});
                else
                    codes{i} = LustreEq(outputs{i}, inputs{1}{i});
                end
            end
        end
        
        function [codes] = getWriteCodeForPortInput(obj, in_matrix_dimension,inputs,outputs,numOutDims,U_expanded_dims,ind,blk)
            %% function get code for noPortInput
            % initialization
            blk_name = SLX2LusUtils.node_name_format(blk);
            indexDataType = 'int';    
            
            if numOutDims>7
                display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
                    blk.Origin_path), ...
                    MsgType.ERROR, 'Assignment_To_Lustre', '');
            end            
            U_index = {};
            addVars = {};
            addVarIndex = 0;
            for i=1:numel(inputs{2})
                U_index{i} = VarIdExpr(sprintf('%s_U_index_%d',...
                    blk_name,i));
                addVars{end + 1} = LustreVar(U_index{i},indexDataType);
            end            
            % pass to Lustre ind
            codes = {};
            for i=1:numel(ind)
                if ~contains(blk.IndexOptionArray{i}, '(port)')
                    for j=1:numel(ind{i})
                        v_name =  sprintf('%s_ind_dim_%d_%d',...
                            blk_name,i,j);
                        addVars{end + 1} = LustreVar(v_name, indexDataType);
                        codes{end + 1} = LustreEq(v_name, IntExpr(ind{i}(j))) ;
                    end
                else
                    % port
                    if strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                        for j=1:numel(ind{i})
                            v_name = sprintf('%s_ind_dim_%d_%d',...
                                blk_name,i,j);
                            addVars{end + 1} = LustreVar(v_name, indexDataType);

                            if j==1
                                codes{end + 1} = LustreEq(v_name, ind{i}{1}) ;
                            else
                                codes{end + 1} = LustreEq(v_name,...
                                    BinaryExpr(BinaryExpr.PLUS,...
                                    IntExpr(ind{i}{1}), ...
                                    IntExpr(j-1))) ;
                                %sprintf('%s_ind_dim_%d_%d = %s + %d;\n\t',...
                                %    blk_name,i,j, ind{i}{1}, (j-1)) ;
                            end
                        end
                    else   % 'Index vector (port)'
                        for j=1:numel(ind{i})
                            v_name = sprintf('%s_ind_dim_%d_%d',...
                                blk_name,i,j);
                            addVars{end + 1} = LustreVar(v_name, indexDataType);
                            codes{end + 1} =  LustreEq(v_name, IntExpr(ind{i}{j}));
                            %sprintf('%s_ind_dim_%d_%d = %s;\n\t',...
                            %    blk_name,i,j, ind{i}{j}) ;
                        end
                    end
                end
            end   
            % dimJump is needed to do sub2ind
            Y0_dimJump = ones(1,numel(in_matrix_dimension{1}.dims));
            for i=2:numel(in_matrix_dimension{1}.dims)
                for j=1:i-1
                    Y0_dimJump(i) = Y0_dimJump(i)*in_matrix_dimension{1}.dims(j);
                end
            end
            U_dimJump = ones(1,numel(U_expanded_dims.dims));
            for i=2:numel(U_expanded_dims.dims)
                for j=1:i-1
                    U_dimJump(i) = U_dimJump(i)*U_expanded_dims.dims(j);
                end
            end
            varId_Y_index = {};
            for i=1:numel(inputs{2})    % looping over U elements
                curSub = ones(1,numel(U_expanded_dims.dims));
                % ind2sub
                [d1, d2, d3, d4, d5, d6, d7 ] = ind2sub(U_expanded_dims.dims,i);   % 7 dims max
                curSub(1) = d1;
                curSub(2) = d2;
                curSub(3) = d3;
                curSub(4) = d4;
                curSub(5) = d5;
                curSub(6) = d6;
                curSub(7) = d7;                
                for j=1:numel(in_matrix_dimension{1}.dims)
                    varId_Y_index{i}{j} = VarIdExpr(...
                        sprintf('%s_str_Y_index_%d_%d',...
                        blk_name,i,j));
                    addVars{end + 1} = LustreVar(varId_Y_index{i}{j}, indexDataType);
                    codes{end + 1} = LustreEq(varId_Y_index{i}{j}, ...
                        VarIdExpr(sprintf('%s_ind_dim_%d_%d',...
                        blk_name,j,curSub(j))));
                    %sprintf('%s = %s_ind_dim_%d_%d;\n\t',...
                    %    str_Y_index{i}{j},blk_name,j,curSub(j)) ;
                end                
                value = IntExpr('0');
                value_terms = cell(1, numel(in_matrix_dimension{1}.dims));
                for j=1:numel(in_matrix_dimension{1}.dims)
                    if j==1
                        value_terms{j} = BinaryExpr(BinaryExpr.MULTIPLY,...
                            varId_Y_index{i}{j}, IntExpr(Y0_dimJump(j)));
                        %value = sprintf('%s + %s*%d',value,str_Y_index{i}{j}, Y0_dimJump(j));
                    else
                        value_terms{j} = BinaryExpr(...
                            BinaryExpr.MULTIPLY,...
                            BinaryExpr(BinaryExpr.MINUS,...
                                        varId_Y_index{i}{j}, ...
                                        IntExpr(1)), ...
                            IntExpr(Y0_dimJump(j)));
                        %value = sprintf('%s + (%s-1)*%d',value,str_Y_index{i}{j}, Y0_dimJump(j));
                    end
                end
                value = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, value_terms);
                codes{end + 1} = LustreEq( U_index{i}, value);
            end
            if numel(in_matrix_dimension{1}.dims) > 7
                
                display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
                    blk.Origin_path), ...
                    MsgType.ERROR, 'Assignment_To_Lustre', '');
            end
            for i=1:numel(outputs)
                conds = {};
                thens = {};
                for j=numel(inputs{2}):-1:1
                    conds{end+1} = BinaryExpr(BinaryExpr.EQ,...
                        U_index{j}, IntExpr(i));
                    thens{end + 1} = inputs{2}{j};
                    %if j==numel(inputs{2})
                       %code = sprintf('%s  if(%s = %d) then %s\n\t', code, U_index{j},i,inputs{2}{j});
                    %else
                     %   code = sprintf('%s  else if(%s = %d) then %s\n\t', code, U_index{j},i,inputs{2}{j});
                    %end
                end
                %codes{end + 1} = sprintf('%s  else %s ;\n\t', code,inputs{1}{i});
                thens{end + 1} = inputs{1}{i};
                code = IteExpr.nestedIteExpr(conds, thens);
                codes{end + 1} = LustreEq( outputs{i}, code);               
            end            
            obj.addVariable(addVars);
        end
        
    end
    
    %%
    methods(Static)
        function in_matrix_dimension = getInputMatrixDimensions(inport_dimensions)
            if inport_dimensions(1) == -2
                % bus case, the first 2 elements should be ignored
                inport_dimensions = inport_dimensions(3:end);
            end
            % return structure of matrix size
            in_matrix_dimension = {};
            readMatrixDimension = true;
            numMat = 0;
            i = 1;
            while i <= numel(inport_dimensions)
                if readMatrixDimension
                    numMat = numMat + 1;
                    if inport_dimensions(i) == -2
                        % bus signal: skip 2 scalars
                        i = i + 2;
                    end
                    numDs = inport_dimensions(i);
                    
                    readMatrixDimension = false;
                    in_matrix_dimension{numMat}.numDs = numDs;
                    in_matrix_dimension{numMat}.dims = zeros(1,numDs);
                    index = 0;
                else
                    index = index + 1;
                    in_matrix_dimension{numMat}.dims(1,index) = inport_dimensions(i);
                    if index == numDs
                        readMatrixDimension = true;
                    end
                end
                i = i + 1;
            end
            
            % add width information
            for i=1:numel(in_matrix_dimension)
                in_matrix_dimension{i}.width = prod(in_matrix_dimension{i}.dims);
            end
        end
        
        %% get block inputs names and also convert input data type to accumulated datatype
        function [inputs] = ...
                getBlockInputsNames_convInType2AccType(obj, parent, blk,isSelector)
            if isSelector
                inputIdToConvertToInt = 1;
            else
                inputIdToConvertToInt = 2;
            end
            inputs = {};
            widths = blk.CompiledPortWidths.Inport;
            %max_width = widths(1);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                [lusInport_dt, ~] = SLX2LusUtils.get_lustre_dt(inport_dt);
                
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType) && i <= 2
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                elseif i > inputIdToConvertToInt && ~strcmp(lusInport_dt, 'int')
                    % convert index values to int for Lustre code
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'int');
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
        end
        
        function [isPortIndex,ind,selectorOutputDimsArray] = ...
                defineMapInd(~,parent,blk,inputs,U_expanded_dims,isSelector)
            % if isSelector then U_expanded_dims should be in_matrix_dimension{1}
            indexPortNumber = 0;
            isPortIndex = false;
            IndexMode = blk.IndexMode;
            indPortNumber = zeros(1,numel(blk.IndexOptionArray));
            [numOutDims, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);            
            selectorOutputDimsArray = ones(1,numOutDims);
            if isSelector
                AssignSelectAll = 'Select all';
                AssignSelectToLustre = 'Selector_To_Lustre';
                portNumberOffset = 1;
            else
                AssignSelectAll = 'Assign all';
                AssignSelectToLustre = 'Assignment_To_Lustre';
                portNumberOffset = 2;  % 1st and 2nd for Y0 and U
            end
            for i=1:numel(blk.IndexOptionArray)
                if strcmp(blk.IndexOptionArray{i}, AssignSelectAll)
                    ind{i} = (1:U_expanded_dims.dims(i));
                    selectorOutputDimsArray(i) = U_expanded_dims.dims(i);
                elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (dialog)')
                    [Idx, ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
                    ind{i} = Idx;
                    selectorOutputDimsArray(i) = numel(Idx);
                elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (port)')
                    isPortIndex = true;
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + portNumberOffset;   
                    indPortNumber(i) = portNumber;
                    selectorOutputDimsArray(i) = numel(inputs{portNumber});
                    for j=1:numel(inputs{portNumber})
                        if strcmp(IndexMode, 'Zero-based')
                            ind{i}{j} = BinaryExpr(BinaryExpr.PLUS,...
                                inputs{portNumber}{j},...
                                IntExpr(1));
                                %sprintf('%s + 1',inputs{portNumber}{j});
                        else
                            ind{i}{j} = inputs{portNumber}{j};
                        end
                    end
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (dialog)')
                    [selectorOutputDimsArray(i), ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.OutputSizeArray{i});
                    [Idx, ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
                    if isSelector
                        ind{i} = (Idx:Idx+selectorOutputDimsArray(i)-1);
                    else
                        % check for scalar or vector
                        if U_expanded_dims.numDs == 1
                            if U_expanded_dims.dims(1) == 1   %scalar
                                ind{i} = Idx;
                            else     %vector
                                ind{i} = (Idx:Idx+U_expanded_dims.dims(1)-1);
                            end
                        else      % matrix
                            ind{i} = (Idx:Idx+U_expanded_dims.dims(i)-1);
                        end
                    end
                    
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                    isPortIndex = true;
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + portNumberOffset;   
                    indPortNumber(i) = portNumber;
                    [selectorOutputDimsArray(i), ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.OutputSizeArray{i});
                    if isSelector
                        for j=1:selectorOutputDimsArray(i)
                            
                            if strcmp(IndexMode, 'Zero-based')
                                ind{i}{j} = BinaryExpr.BinaryMultiArgs(...
                                    BinaryExpr.PLUS, ...
                                    {...
                                        inputs{portNumber}{1}, ...
                                        IntExpr(1), ...
                                        IntExpr(j-1)...
                                    });
                                %sprintf('%s + 1 + %d',inputs{portNumber}{1},(j-1));
                            else
                                ind{i}{j} = BinaryExpr(BinaryExpr.PLUS,...
                                    inputs{portNumber}{1},...
                                    IntExpr(j-1));
                                    %sprintf('%s + %d',inputs{portNumber}{1},(j-1));
                            end
                        end
                    else
                        if U_expanded_dims.numDs == 1
                            jend = U_expanded_dims.dims(1);
                        else
                            jend = U_expanded_dims.dims(i);
                        end
                        for j=1:jend
                            if j==1
                                if strcmp(IndexMode, 'Zero-based')
                                    ind{i}{j} = BinaryExpr(BinaryExpr.PLUS,...
                                        inputs{portNumber}{1},...
                                        IntExpr(1));
                                    %sprintf('%s + 1',inputs{portNumber}{1});
                                else
                                    ind{i}{j} = inputs{portNumber}{j};
                                end
                            else
                                if strcmp(IndexMode, 'Zero-based')
                                    ind{i}{j} = BinaryExpr.BinaryMultiArgs(...
                                        BinaryExpr.PLUS, ...
                                        {...
                                            inputs{portNumber}{1}, ...
                                            IntExpr(1), ...
                                            IntExpr(j-1)...
                                        });
                                    %sprintf('%s + 1 + d',inputs{portNumber}{1},(j-1));
                                else
                                    ind{i}{j} = BinaryExpr(BinaryExpr.PLUS,...
                                        inputs{portNumber}{1},...
                                        IntExpr(j-1));
                                    %sprintf('%s + d',inputs{portNumber}{1},(j-1));
                                end
                            end
                        end
                    end
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting and ending indices (port)')
                     display_msg(sprintf('IndexOption  %s not supported in block %s',...
                        blk.IndexOptionArray{i}, blk.Origin_path), ...
                        MsgType.ERROR, AssignSelectToLustre, '');                   
                else
                    % should not be here
                    display_msg(sprintf('IndexOption  %s not recognized in block %s',...
                        blk.IndexOptionArray{i}, blk.Origin_path), ...
                        MsgType.ERROR, AssignSelectToLustre, '');
                end
                if strcmp(IndexMode, 'Zero-based') && indPortNumber(i) == 0
                    if ~strcmp(blk.IndexOptionArray{i}, AssignSelectAll)
                        ind{i} = ind{i} + 1;
                    end
                end
            end
        end
        
    end
    
end

