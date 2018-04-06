classdef Assignment_To_Lustre < Block_To_Lustre
    % Assignment_To_Lustre
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
            max_width = max(widths);
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
            

            [numOutDims, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);
            
            codes = {};
            codeIndex = 0;
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk);
%             siz = zeros(1,numel(in_matrix_dimension));
%             for i=1:numel(in_matrix_dimension)
%                 siz(i) = in_matrix_dimension{i}.numDs;
%             end

            % reading and assigning index map ind{i}
            % ind{i}   mapping index for dimension i.   e.g.   ind{1} =
            % [1,3] means for dimension 1, U has 2 rows, 1st row of U maps
            % to 1 row of Y, 2nd row of U maps to 3rd row of Y  
            % for non "port" row i, ind{i} is an array of integer
            % for "port" row i, ind{i} is an array of string for Lustre
            % code
            indexPortNumber = 0;
            isPortIndex = false;
            IndexMode = blk.IndexMode;
            indPortNumber = zeros(1,numel(blk.IndexOptionArray));
            for i=1:numel(blk.IndexOptionArray)
                if strcmp(blk.IndexOptionArray{i}, 'Assign all')
                    ind{i} = (1:in_matrix_dimension{2}.dims(i));
                elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (dialog)')
                    [Idx, ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
                    ind{i} = Idx;
                elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (port)')
                    isPortIndex = true;
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + 2;   % 1st and 2nd for Y0 and U
                    indPortNumber(i) = portNumber;
                    for j=1:in_matrix_dimension{2}.dims(i)
                        if strcmp(IndexMode, 'Zero-based')
                            ind{i}{j} = sprintf('%s + 1',inputs{portNumber}{j});
                        else
                            ind{i}{j} = inputs{portNumber}{j};
                        end
                    end
                    %ind{i} = cell(in_matrix_dimension{2}.dims(i));
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (dialog)')
                    [Idx, ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
                    % check for scalar or vector
                    if in_matrix_dimension{2}.numDs == 1
                        if in_matrix_dimension{2}.dims(1) == 1   %scalar
                            ind{i} = Idx;
                        else     %vector
                            ind{i} = (Idx:Idx+in_matrix_dimension{2}.dims(1)-1);
                        end
                    else      % matrix
                        ind{i} = (Idx:Idx+in_matrix_dimension{2}.dims(i)-1);
                    end
                    
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                    isPortIndex = true;
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + 2;   % 1st and 2nd for Y0 and U    
                    indPortNumber(i) = portNumber;
                    for j=1:in_matrix_dimension{2}.dims(i)                        
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
                if strcmp(IndexMode, 'Zero-based')
                    if ~strcmp(blk.IndexOptionArray{i}, 'Assign all')
                        ind{i} = ind{i} + 1;
                    end
                end
            end
            
            U_to_Y0 = zeros(1,numel(inputs{2}));
            y0_dims = in_matrix_dimension{1}.dims;    % y0_dims = U_dims
            U_dims = in_matrix_dimension{2}.dims;
            indexDataType = 'int';
            
            % if index assignment is read in form index port, write mapping
            % code on Lustre side
            if isPortIndex
                
                if numOutDims>7
                    display_msg(sprintf('For index option %s, more than 7 dimensions is not supported in block %s',...
                        blk.IndexOptionArray{i}, indexBlock.Origin_path), ...
                        MsgType.ERROR, 'Assignment_To_Lustre', '');
                end
                
                U_index = {};
                addVars = {};
                addVarIndex = 0;
                for i=1:numel(inputs{2})
                    U_index{i} = sprintf('U_index_%d',i);
                    addVarIndex = addVarIndex + 1;
                    addVars{addVarIndex} = sprintf('%s:%s;',U_index{i},indexDataType);
                end
                
                % pass to Lustre ind
                for i=1:numel(ind)
                    if ~contains(blk.IndexOptionArray{i}, '(port)')
                        for j=1:numel(ind{i})
                            addVarIndex = addVarIndex + 1;
                            addVars{addVarIndex} = sprintf('ind_dim_%d_%d:%s;',i,j,indexDataType);
                            codeIndex = codeIndex + 1;
                            codes{codeIndex} = sprintf('ind_dim_%d_%d = %d;\n\t',i,j, ind{i}(j)) ;
                        end
                    else
                        % port
                        portNum = indPortNumber(i);
                        if strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                            for j=1:numel(ind{i})
                                addVarIndex = addVarIndex + 1;
                                addVars{addVarIndex} = sprintf('ind_dim_%d_%d:%s;',i,j,indexDataType);
                                codeIndex = codeIndex + 1;
                                if j==1
                                    codes{codeIndex} = sprintf('ind_dim_%d_%d = %s;\n\t',i,j, inputs{portNum}{1}) ;
                                else
                                    codes{codeIndex} = sprintf('ind_dim_%d_%d = %s + %d;\n\t',i,j, inputs{portNum}{1}, (j-1)) ;
                                end
                            end                            
                        else   % 'Index vector (port)'
                            for j=1:numel(ind{i})
                                addVarIndex = addVarIndex + 1;
                                addVars{addVarIndex} = sprintf('ind_dim_%d_%d:%s;',i,j,indexDataType);
                                codeIndex = codeIndex + 1;
                                codes{codeIndex} = sprintf('ind_dim_%d_%d = %s;\n\t',i,j, inputs{portNum}{j}) ;
                            end
                        end
                    end
                end
                %calculating U_index{i}
                % 1D
                
                Y0_dimJump = ones(1,numel(in_matrix_dimension{1}.dims));
                for i=2:numel(in_matrix_dimension{1}.dims)
                    for j=1:i-1
                        Y0_dimJump(i) = Y0_dimJump(i)*in_matrix_dimension{1}.dims(j);
                    end
                end
                U_dimJump = ones(1,numel(in_matrix_dimension{2}.dims));
                for i=2:numel(in_matrix_dimension{2}.dims)
                    for j=1:i-1
                        U_dimJump(i) = U_dimJump(i)*in_matrix_dimension{2}.dims(j);
                    end
                end
                str_Y_index = {};
                for i=1:numel(inputs{2})    % looping over U elements
                    curSub = ones(1,numel(in_matrix_dimension{2}.dims));
                    curNum = i;
                    % ind2sub
                    [d1, d2, d3, d4, d5, d6, d7 ] = ind2sub(in_matrix_dimension{2}.dims,i);   % 7 dims max
                    curSub(1) = d1;
                    curSub(2) = d2;
                    curSub(3) = d3;
                    curSub(4) = d4;
                    curSub(5) = d5;
                    curSub(6) = d6;
                    curSub(7) = d7;
                    %                     for j=numel(in_matrix_dimension{2}.dims):-1:1
                    %                         if j==1
                    %                             curSub(j) = floor(curNum/U_dimJump(j));
                    %                         else
                    %                             curSub(j) = floor(curNum/U_dimJump(j))+1;
                    %                         end
                    %                         curNum = rem(curNum,U_dimJump(j));
                    %                     end
                    for j=1:numel(in_matrix_dimension{2}.dims)
                        Y_index{j} = ind{j}(curSub(j));
                        str_Y_index{i}{j} = sprintf('str_Y_index_%d_%d',i,j);
                        addVarIndex = addVarIndex + 1;
                        addVars{addVarIndex} = sprintf('str_Y_index_%d_%d:%s;',i,j,indexDataType);
                        codeIndex = codeIndex + 1;
                        codes{codeIndex} = sprintf('%s = ind_dim_%d_%d;\n\t',str_Y_index{i}{j},j,curSub(j)) ;
                    end
                    
                    value = '0';
                    for j=1:numel(in_matrix_dimension{2}.dims)
                        if j==1
                            value = sprintf('%s + %s*%d',value,str_Y_index{i}{j}, Y0_dimJump(j))
                        else
                            value = sprintf('%s + (%s-1)*%d',value,str_Y_index{i}{j}, Y0_dimJump(j))
                        end
                    end
                    codeIndex = codeIndex + 1;
                    codes{codeIndex} = sprintf('%s = %s;\n\t', U_index{i}, value)
                end
                if numel(in_matrix_dimension{1}.dims) > 7
                    
                    display_msg(sprintf('More than 3 dimensions is not supported in block %s',...
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
                
            else
                if in_matrix_dimension{1}.numDs == 1   % for 1D
                    U_to_Y0 = ind{1};
                else
                    % support max dimensions = 7
                    sub2ind_string = 'U_to_Y0 = sub2ind(y0_dims';
                    dString = {'[ ', '[ ', '[ ', '[ ', '[ ', '[ ', '[ '};
                    
                    for i=1:numel(inputs{2})    % looping over U elements
                        [d1, d2, d3, d4, d5, d6, d7 ] = ind2sub(U_dims,i);
                        d = [d1, d2, d3, d4, d5, d6, d7 ];
                        
                        for j=1:numel(y0_dims)
                            y0d(j) = ind{j}(d(j));
                            if i==1
                                dString{j}  = sprintf('%s%d', dString{j}, y0d(j));
                            else
                                dString{j}  = sprintf('%s, %d', dString{j}, y0d(j));
                            end
                        end
                    end
                    
                    for j=1:numel(y0_dims)
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
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, blk, varargin)
            obj.unsupported_options = {};
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk);
            if in_matrix_dimension{1}.numDs>7
                obj.addUnsupported_options(...
                    sprintf('More than 7 dimensions is not supported in block %s',...
                    indexBlock.Origin_path), ...
                    MsgType.ERROR, 'Assignment_To_Lustre', '');
            end
            
            options = obj.unsupported_options;
        end
    end
    
    
    methods(Static)
        % This method allows for only 1 input, the same static under
        % Product_To_Lustre may require more than 1 input
        function in_matrix_dimension = getInputMatrixDimensions(blk)
            % return structure of matrix size
            in_matrix_dimension = {};
            readMatrixDimension = true;
            numMat = 0;
            inport_dimensions = blk.CompiledPortDimensions.Inport;
            
            for i=1:numel(inport_dimensions)
                if readMatrixDimension
                    numMat = numMat + 1;
                    numDs = inport_dimensions(i);
                    readMatrixDimension = false;
                    in_matrix_dimension{numMat}.numDs = numDs;
                    in_matrix_dimension{numMat}.dims = zeros(1,numDs);
                    index = 0;
                else
                    index = index + 1;
                    in_matrix_dimension{numMat}.dims(1,index) = inport_dimensions(i);
                    if index == numDs;
                        readMatrixDimension = true;
                    end
                end
                
            end
        end
        
    end
    
end

