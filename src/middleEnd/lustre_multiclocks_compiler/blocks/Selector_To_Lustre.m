classdef Selector_To_Lustre < Block_To_Lustre
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
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk);
            inputs = {};
            
            widths = blk.CompiledPortWidths.Inport;
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
                elseif i > 1 && ~strcmp(lusInport_dt, 'int')
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
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);

            % reading and assigning index map ind{i}
            % ind{i} is the mapping i for dimension i.   e.g.   ind{1} =
            % [1,3] means for dimension 1, select row 1 and 3.
            % for non "port" row i, ind{i} is an array of integer
            % for "port" row i, ind{i} is an array of string for Lustre
            % code
            indexPortNumber = 0;
            isPortIndex = false;
            IndexMode = blk.IndexMode;
            indPortNumber = zeros(1,numel(blk.IndexOptionArray));
            outputDimsArray = ones(1,numOutDims);

            for i=1:numel(blk.IndexOptionArray)
                [outputDimsArray(i), ~, ~] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, blk.OutputSizeArray{i});
                if strcmp(blk.IndexOptionArray{i}, 'Select all')
                    ind{i} = (1:in_matrix_dimension{1}.dims(i));
                    outputDimsArray(i) = in_matrix_dimension{1}.dims(i);
                elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (dialog)')
                    [Idx, ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
                    ind{i} = Idx;
                    outputDimsArray(i) = numel(Idx);
                elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (port)')
                    isPortIndex = true;
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + 1;   % 1st is for input
                    indPortNumber(i) = portNumber;
                    outputDimsArray(i) = numel(inputs{portNumber});
                    for j=1:outputDimsArray(i)
                        if strcmp(IndexMode, 'Zero-based')
                            ind{i}{j} = sprintf('%s + 1',inputs{portNumber}{j});
                        else
                            ind{i}{j} = inputs{portNumber}{j};
                        end
                    end
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (dialog)')
                    [Idx, ~, ~] = ...
                        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});                    
                    ind{i} = (Idx:Idx+outputDimsArray(i)-1);
                    
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
                    isPortIndex = true;
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + 1;   % 1st is for input
                    indPortNumber(i) = portNumber;

                    for j=1:outputDimsArray(i)
                        
                        if strcmp(IndexMode, 'Zero-based')
                            ind{i}{j} = sprintf('%s + 1 + %d',inputs{portNumber}{1},(j-1));
                        else
                            ind{i}{j} = sprintf('%s + %d',inputs{portNumber}{1},(j-1));
                        end                        
                    end
                    
                elseif strcmp(blk.IndexOptionArray{i}, 'Starting and ending indices (port)')      
                    isPortIndex = true;
                    indexPortNumber = indexPortNumber + 1;
                    portNumber = indexPortNumber + 1;   % 1st is for input
                    indPortNumber(i) = portNumber;
                    outputDimsArray(i) = numel(inputs{portNumber});
                    for j=1:outputDimsArray(i)
                        if strcmp(IndexMode, 'Zero-based')
                            ind{i}{j} = sprintf('%s + 1',inputs{portNumber}{j});
                        else
                            ind{i}{j} = inputs{portNumber}{j};
                        end
                    end                 
                    display_msg(sprintf('Starting and ending indices (port) is not supported in block %s',...
                        blk.Origin_path), ...
                        MsgType.ERROR, 'Selector_To_Lustre', '');    
                   
                else
                    % should not be here
                    display_msg(sprintf('IndexOption  %s not recognized in block %s',...
                        blk.IndexOptionArray{i}, indexBlock.Origin_path), ...
                        MsgType.ERROR, 'Selector_To_Lustre', '');
                end
                if strcmp(IndexMode, 'Zero-based') && indPortNumber(i) == 0
                    if ~strcmp(blk.IndexOptionArray{i}, 'Select all')
                        ind{i} = ind{i} + 1;
                    end
                end
            end
            
            indexDataType = 'int';
            
            % if index assignment is read in form index port, write mapping
            % code on Lustre side
            if isPortIndex   
                
                if numOutDims>7
                    display_msg(sprintf('For index option %s, more than 7 dimensions is not supported in block %s',...
                        blk.IndexOptionArray{i}, indexBlock.Origin_path), ...
                        MsgType.ERROR, 'Selector_To_Lustre', '');
                end
                
                U_index = {};
                addVars = {};
                addVarIndex = 0;
                blk_name = SLX2LusUtils.node_name_format(blk);
                for i=1:numel(outputs)
                    U_index{i} = sprintf('%s_U_index_%d',blk_name,i);
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
                        portNum = indPortNumber(i);
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
                %calculating U_index{i}
                % 1D
                
                Y_dimJump = ones(1,numel(outputDimsArray));
                for i=2:numel(outputDimsArray)
                    for j=1:i-1
                        Y_dimJump(i) = Y_dimJump(i)*outputDimsArray(j);
                    end
                end
                U_dimJump = ones(1,numel(in_matrix_dimension{1}.dims));
                for i=2:numel(in_matrix_dimension{1}.dims)
                    for j=1:i-1
                        U_dimJump(i) = U_dimJump(i)*in_matrix_dimension{1}.dims(j);
                    end
                end
                str_Y_index = {};
                for i=1:numel(outputs)  % looping over Y elements
                    curSub = ones(1,numel(outputDimsArray));
                    % ind2sub
                    [d1, d2, d3, d4, d5, d6, d7 ] = ind2sub(outputDimsArray,i);   % 7 dims max
                    curSub(1) = d1;
                    curSub(2) = d2;
                    curSub(3) = d3;
                    curSub(4) = d4;
                    curSub(5) = d5;
                    curSub(6) = d6;
                    curSub(7) = d7;

                    for j=1:numel(outputDimsArray)
                        str_Y_index{i}{j} = sprintf('%s_str_Y_index_%d_%d',...
                           blk_name,i,j);
                        addVarIndex = addVarIndex + 1;
                        addVars{addVarIndex} = sprintf('%s_str_Y_index_%d_%d:%s;',...
                           blk_name,i,j,indexDataType);
                        codeIndex = codeIndex + 1;
                        codes{codeIndex} = sprintf('%s = %s_ind_dim_%d_%d;\n\t',...
                            str_Y_index{i}{j},blk_name,j,curSub(j)) ;
                    end
                    
                    % calculating sub2ind in Lustre
                    value = '0';
                    for j=1:numel(outputDimsArray)
                        if j==1
                            value = sprintf('%s + %s*%d',value,str_Y_index{i}{j}, U_dimJump(j));
                        else
                            value = sprintf('%s + (%s-1)*%d',value,str_Y_index{i}{j}, U_dimJump(j));
                        end
                    end
                    codeIndex = codeIndex + 1;
                    codes{codeIndex} = sprintf('%s = %s;\n\t', U_index{i}, value);
                end
                if numel(in_matrix_dimension{1}.dims) > 7                    
                    display_msg(sprintf('More than 7 dimensions is not supported in block %s',...
                        indexBlock.Origin_path), ...
                        MsgType.ERROR, 'Selector_To_Lustre', '');
                end
                
                % writing outputs code
                for i=1:numel(outputs)
                    codeIndex = codeIndex + 1;
                    code = sprintf('%s = \n\t', outputs{i});
                    for j=numel(inputs{1}):-1:2
                        if j==numel(inputs{1})
                            code = sprintf('%s  if(%s = %d) then %s\n\t', code, U_index{i},j,inputs{1}{j});
                        else
                            code = sprintf('%s  else if(%s = %d) then %s\n\t', code, U_index{i},j,inputs{1}{j});
                        end
                    end
                    codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,inputs{1}{1});
                    
                end
                
                obj.addVariable(addVars);
                
            else   % no port input.  Mapping is done in Matlab.
                if numOutDims > 7
                    display_msg(sprintf('For index option %s, more than 7 dimensions is not supported in block %s',...
                        blk.IndexOptionArray{i}, indexBlock.Origin_path), ...
                        MsgType.ERROR, 'Selector_To_Lustre', '');
                elseif numOutDims == 1
                    for i=1:numel(outputs)
                        codeIndex = codeIndex + 1;
                        U_index = ind{1}(i);
                        codes{codeIndex} = sprintf('%s = %s ;\n\t', outputs{i}, inputs{1}{U_index});
                    end                    
                else
                    % support max dimensions = 7                    
                    for i=1:numel(outputs)
                        codeIndex = codeIndex + 1;
                        [d1, d2, d3, d4, d5, d6, d7 ] = ind2sub(outputDimsArray,i);
                        d = [d1, d2, d3, d4, d5, d6, d7 ];
                        
                        sub2ind_string = 'U_index = sub2ind(in_matrix_dimension{1}.dims';
                        dString = {'[ ', '[ ', '[ ', '[ ', '[ ', '[ ', '[ '};
                        for j=1:numOutDims
                            Ud(j) = ind{j}(d(j));
                            if i==1
                                dString{j}  = sprintf('%s%d', dString{j}, Ud(j));
                            else
                                dString{j}  = sprintf('%s, %d', dString{j}, Ud(j));
                            end
                        end
                        
                        for j=1:numOutDims
                            sub2ind_string = sprintf('%s, %s]',sub2ind_string,dString{j});
                        end
                        
                        sub2ind_string = sprintf('%s);',sub2ind_string);
                        eval(sub2ind_string);
                        codes{codeIndex} = sprintf('%s = %s ;\n\t', outputs{i}, inputs{1}{U_index});
                    end
                    
                end
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            [numOutDims, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);
            if numOutDims>7
                obj.addUnsupported_options(...
                    sprintf('More than 7 dimensions is not supported in block %s',...
                    indexBlock.Origin_path), ...
                    MsgType.ERROR, 'Selector_To_Lustre', '');
            end
            
            options = obj.unsupported_options;
        end
    end
        
end

