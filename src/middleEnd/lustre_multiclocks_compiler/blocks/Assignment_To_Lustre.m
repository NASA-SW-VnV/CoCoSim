classdef Assignment_To_Lustre < Block_To_Lustre
    % Assignment_To_Lustre
    % Key to this task is understanding and using the mapping cell array
    % ind. ind{i} maps index for dimension i.
    %      -  ind{1} = [1,3] means for dimension 1, U has 2 rows (length of array), 1st row of U maps
    %      to 1st row of Y, 2nd row of U maps to 3rd row of Y
    %      -  for non "port" row i, ind{i} is an array of integer
    %      -  for "port" row i, ind{i} is an array of string for Lustre code
    %      -  when the input of U is a scalar but meant to be expanded to fill up
    %      the length of a dimension, expand U first so the
    %      definition of ind doesn't change.  
    %      
    % There are 2 different coding schemes.  If a dimension is not a port input,
    % the index assignment logic is done by Matlab and the array of that dimension are numeric.  
    % If a dimension is aport
    % input, the logic is done by Lustre and the array of that dimension are string to be used in Lustre. 
    
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
            
            % getBlockInputsOutputs
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk);
            [inputs] = ...
                getBlockInputsNames_convInType2AccType(obj, parent, blk);
        
            [numOutDims, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);   
            
            % get matrix dimension of all inputs, and expand U if needed.
            [in_matrix_dimension, U_expanded_dims] = get_In_U_expanded_dims(obj,parent,blk,inputs,numOutDims);
            
            % inputs is also expanded if U is expanded
            U_size = 1;   
            for i=1:numOutDims
                U_size = U_size*U_expanded_dims.dims(i);
            end
            if numel(inputs{2}) == 1 && numel(inputs{2}) < U_size
                inputs{2} = arrayfun(@(x) {inputs{2}{1}}, (1:U_size));
            end             
            
            % define mapping array ind
            [isPortIndex,ind] = defineMapInd(obj,parent,blk,U_expanded_dims,inputs);
           
            % if index assignment is read in from index port, write mapping
            % code on Lustre side
            if isPortIndex
                [codes] = getWriteCodeForPortInput(obj, in_matrix_dimension,inputs,outputs,numOutDims,U_expanded_dims,ind,blk);                
            else  % no port input
                [codes] = getWriteCodeForNonPortInput(obj,in_matrix_dimension,inputs,outputs,U_expanded_dims,ind);                
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function [isPortIndex,ind] = defineMapInd(obj,parent,blk,U_expanded_dims,inputs)
            indexPortNumber = 0;
            isPortIndex = false;
            IndexMode = blk.IndexMode;
            indPortNumber = zeros(1,numel(blk.IndexOptionArray));
            for i=1:numel(blk.IndexOptionArray)
                if strcmp(blk.IndexOptionArray{i}, 'Assign all')
                    ind{i} = (1:U_expanded_dims.dims(i));
                elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (dialog)')
                    [Idx, ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
                    ind{i} = Idx;
                elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (port)')
                    isPortIndex = true;
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + 2;   % 1st and 2nd for Y0 and U
                    indPortNumber(i) = portNumber;
                    for j=1:numel(inputs{portNumber})
                        if strcmp(IndexMode, 'Zero-based')
                            ind{i}{j} = sprintf('%s + 1',inputs{portNumber}{j});
                        else
                            ind{i}{j} = inputs{portNumber}{j};
                        end
                    end
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (dialog)')
                    [Idx, ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
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
                    
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                    isPortIndex = true;
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + 2;   % 1st and 2nd for Y0 and U    
                    indPortNumber(i) = portNumber;
                    
                    
                    if U_expanded_dims.numDs == 1
                        jend = U_expanded_dims.dims(1);
                    else
                        jend = U_expanded_dims.dims(i);
                    end
                    for j=1:jend                      
                        if j==1
                            if strcmp(IndexMode, 'Zero-based')
                                ind{i}{j} = sprintf('%s + 1',inputs{portNumber}{1});
                            else
                                ind{i}{j} = inputs{portNumber}{j};
                            end
                        else                            
                            if strcmp(IndexMode, 'Zero-based')
                                ind{i}{j} = sprintf('%s + 1 + d',inputs{portNumber}{1},(j-1));
                            else
                                ind{i}{j} = sprintf('%s + d',inputs{portNumber}{1},(j-1));
                            end
                        end
                    end   
                    
                else
                    % should not be here
                    display_msg(sprintf('IndexOption  %s not recognized in block %s',...
                        blk.IndexOptionArray{i}, indexBlock.Origin_path), ...
                        MsgType.ERROR, 'Assignment_To_Lustre', '');
                end
                if strcmp(IndexMode, 'Zero-based') && indPortNumber(i) == 0
                    if ~strcmp(blk.IndexOptionArray{i}, 'Assign all')
                        ind{i} = ind{i} + 1;
                    end
                end
            end            
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
            if in_matrix_dimension{1}.numDs>7
                obj.addUnsupported_options(...
                    sprintf('More than 7 dimensions is not supported in block %s',...
                    indexBlock.Origin_path), ...
                    MsgType.ERROR, 'Assignment_To_Lustre', '');
            end
            
            options = obj.unsupported_options;
        end
        
        %% get block inputs names and also convert input data type to accumulated datatype
        function [inputs] = ...
                getBlockInputsNames_convInType2AccType(obj, parent, blk)
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
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                elseif i > 2 && ~strcmp(lusInport_dt, 'int')
                    % convert index values to int for Lustre code
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'int');
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
        end       
        
        function [in_matrix_dimension, U_expanded_dims] = get_In_U_expanded_dims(obj, parent,blk,inputs,numOutDims)
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
            U_expanded_dims = in_matrix_dimension{2};
            % if U input is a scalar and it is to be expanded, U_expanded_dims
            % needed to be calculated.
            indexPortNumber = 0;
            if numel(inputs{2}) == 1
                U_expanded_dims.numDs = numOutDims;   
                U_expanded_dims.dims = ones(1,numOutDims);
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
                        %  indexPortNumber = indexPortNumber + 1;
                        %  portNumber = indexPortNumber + 2;
                        U_expanded_dims.dims(i) = 1;
                    else
                    end
                end
            end
        end        
        
        function [codes] = getWriteCodeForNonPortInput(obj, in_matrix_dimension,inputs,outputs,U_expanded_dims,ind)
            %% function get code for noPortInput
            
            % initialization
            codes = {};           
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
            
            codeIndex = 0;
            for i=1:numel(outputs)
                codeIndex = codeIndex + 1;
                if find(U_to_Y0==i)
                    Uindex = find(U_to_Y0==i);
                    codes{codeIndex} = sprintf('%s = %s ;\n\t', outputs{i}, inputs{2}{Uindex});
                else
                    codes{codeIndex} = sprintf('%s = %s ;\n\t', outputs{i}, inputs{1}{i});
                end
            end
        end
        
        function [codes] = getWriteCodeForPortInput(obj, in_matrix_dimension,inputs,outputs,numOutDims,U_expanded_dims,ind,blk)
            %% function get code for noPortInput
            % initialization
            blk_name = SLX2LusUtils.node_name_format(blk);
            indexDataType = 'int';    
            codes = {};
            codeIndex = 0;            
            if numOutDims>7
                display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
                    indexBlock.Origin_path), ...
                    MsgType.ERROR, 'Assignment_To_Lustre', '');
            end            
            U_index = {};
            addVars = {};
            addVarIndex = 0;
            for i=1:numel(inputs{2})
                U_index{i} = sprintf('%s_U_index_%d',...
                    blk_name,i);
                addVarIndex = addVarIndex + 1;
                addVars{addVarIndex} = sprintf('%s:%s;',U_index{i},indexDataType);
            end            
            % pass to Lustre ind
            for i=1:numel(ind)
                if ~contains(blk.IndexOptionArray{i}, '(port)')
                    for j=1:numel(ind{i})
                        addVarIndex = addVarIndex + 1;
                        addVars{addVarIndex} = sprintf('%s_ind_dim_%d_%d:%s;',...
                            blk_name,i,j,indexDataType);
                        codeIndex = codeIndex + 1;
                        codes{codeIndex} = sprintf('%s_ind_dim_%d_%d = %d;\n\t',...
                            blk_name,i,j, ind{i}(j)) ;
                    end
                else
                    % port
                    if strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                        for j=1:numel(ind{i})
                            addVarIndex = addVarIndex + 1;
                            addVars{addVarIndex} = sprintf('%s_ind_dim_%d_%d:%s;',...
                                blk_name,i,j,indexDataType);
                            codeIndex = codeIndex + 1;
                            if j==1
                                codes{codeIndex} = sprintf('%s_ind_dim_%d_%d = %s;\n\t',...
                                    blk_name,i,j, ind{i}{1}) ;
                            else
                                codes{codeIndex} = sprintf('%s_ind_dim_%d_%d = %s + %d;\n\t',...
                                    blk_name,i,j, ind{i}{1}, (j-1)) ;
                            end
                        end
                    else   % 'Index vector (port)'
                        for j=1:numel(ind{i})
                            addVarIndex = addVarIndex + 1;
                            addVars{addVarIndex} = sprintf('%s_ind_dim_%d_%d:%s;',...
                                blk_name,i,j,indexDataType);
                            codeIndex = codeIndex + 1;
                            codes{codeIndex} = sprintf('%s_ind_dim_%d_%d = %s;\n\t',...
                                blk_name,i,j, ind{i}{j}) ;
                        end
                    end
                end
            end   
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
            str_Y_index = {};
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
                    str_Y_index{i}{j} = sprintf('%s_str_Y_index_%d_%d',...
                        blk_name,i,j);
                    addVarIndex = addVarIndex + 1;
                    addVars{addVarIndex} = sprintf('%s_str_Y_index_%d_%d:%s;',...
                        blk_name,i,j,indexDataType);
                    codeIndex = codeIndex + 1;
                    codes{codeIndex} = sprintf('%s = %s_ind_dim_%d_%d;\n\t',...
                        str_Y_index{i}{j},blk_name,j,curSub(j)) ;
                end                
                value = '0';
                for j=1:numel(in_matrix_dimension{1}.dims)
                    if j==1
                        value = sprintf('%s + %s*%d',value,str_Y_index{i}{j}, Y0_dimJump(j));
                    else
                        value = sprintf('%s + (%s-1)*%d',value,str_Y_index{i}{j}, Y0_dimJump(j));
                    end
                end
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s = %s;\n\t', U_index{i}, value);
            end
            if numel(in_matrix_dimension{1}.dims) > 7
                
                display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
                    indexBlock.Origin_path), ...
                    MsgType.ERROR, 'Assignment_To_Lustre', '');
            end
            for i=1:numel(outputs)
                codeIndex = codeIndex + 1;
                code = sprintf('%s = \n\t', outputs{i});
                for j=numel(inputs{2}):-1:1
                    if j==numel(inputs{2})
                        code = sprintf('%s  if(%s = %d) then %s\n\t', code, U_index{j},i,inputs{2}{j});
                    else
                        code = sprintf('%s  else if(%s = %d) then %s\n\t', code, U_index{j},i,inputs{2}{j});
                    end
                end
                codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,inputs{1}{i});               
            end            
            obj.addVariable(addVars);
        end
        
    end
    
    
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
        
    end
    
end

