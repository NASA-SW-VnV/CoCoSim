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
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType)
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            
            %             OutputInitialize = blk.OutputInitialize;
            [numOutDims, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);

            codes = {};
                        
            in_matrix_dimension = Reshape_To_Lustre.getInputMatrixDimensions(blk);
            siz = zeros(1,numel(in_matrix_dimension));
            for i=1:numel(in_matrix_dimension)
                siz(i) = in_matrix_dimension{i}.numDs;
            end
            
            indexPortNumber = 0;
            isPortIndex = false;
            IndexMode = blk.IndexMode;
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
                    indexBlock = SLX2LusUtils.getpreBlock(parent, blk, portNumber);
                    [ind{i}, ~, status] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, indexBlock, indexBlock.Value);
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
                    indexBlock = SLX2LusUtils.getpreBlock(parent, blk, portNumber);
                    [startIndex, ~, status] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, indexBlock, indexBlock.Value);
                    % check for scalar or vector
                    if in_matrix_dimension{2}.numDs == 1
                        if in_matrix_dimension{2}.dims(1) == 1   %scalar
                            ind{i} = Idx;
                        else     %vector
                            ind{i} = (Idx:Idx+in_matrix_dimension{2}.dims(1)-1);
                        end
                    else      % matrix                    
                        ind{i} = (startIndex:startIndex+in_matrix_dimension{2}.dims(i)-1);
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
            
            %if isPortIndex
            if false
                if numOutDims==1
                    
                elseif numOutDims==2
                    
                elseif numOutDims==3
                    
                else                    
                    display_msg(sprintf('For index option %s, more than 3 dimensions is not supported in block %s',...
                        blk.IndexOptionArray{i}, indexBlock.Origin_path), ...
                        MsgType.ERROR, 'Assignment_To_Lustre', '');
                end 
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

