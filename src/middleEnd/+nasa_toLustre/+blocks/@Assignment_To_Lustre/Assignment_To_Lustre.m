classdef Assignment_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
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
    % Copyright (c) 2019 United States Government as represented by the
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
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            % for the example above (assignment_mixed_port_u_expanded.slx): 
            % outputs = {{'Assignment_1'}    {'Assignment_2'}    {'Assignment_3'}    {'Assignment_4'}    {'Assignment_5'}  {'Assignment_6'}}
            % outputs_dt = {'Assignment_1: real;', 'Assignment_2: real;',
            %               'Assignment_3: real;','Assignment_4: real;', 'Assignment_5: real;',
            %               'Assignment_6: real;'}            
            
            [inputs] = ...
                nasa_toLustre.blocks.Assignment_To_Lustre.getBlockInputsNames_convInType2AccType(obj, parent, blk,isSelector);
            % For the exmple above:
            % inputs{1} = 'In1_1'    'In1_2'    'In1_3'  'In1_4'    'In1_5'    'In1_6'
            % inputs{2} = 'Constant1_1'
            % inputs{3} = 'real_to_int(Saturation_1)'
   
            [numOutDims, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);   
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
            [isPortIndex,ind,~] = nasa_toLustre.blocks.Assignment_To_Lustre.defineMapInd(obj,parent,blk,inputs,U_expanded_dims,isSelector);
            % For the example above
            % isPortIndex = 1
            % ind{1} = [1,3]  
            % ind{2} = 'real_to_int(Saturation_1)' 
           
            % if index assignment is read in from index port, write mapping
            % code on Lustre side
            if isPortIndex
                [codes] = getWriteCodeForPortInput(obj, in_matrix_dimension,inputs,outputs,numOutDims,U_expanded_dims,ind,blk);                
            else  % no port input
                [codes] = getWriteCodeForNonPortInput(obj,in_matrix_dimension,inputs,outputs,numOutDims,U_expanded_dims,ind);                
            end
            
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
        end
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            
            in_matrix_dimension = nasa_toLustre.blocks.Assignment_To_Lustre.getInputMatrixDimensions(blk.CompiledPortDimensions.Inport);
            if in_matrix_dimension{1}.numDs>7
                msg = sprintf('More than 7 dimensions is not supported in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path));
                obj.addUnsupported_options(msg);
            end
            if strcmp(blk.OutputInitialize, 'Specify size for each dimension in table')
                msg = sprintf('OutputInitialize Parameter in block %s is not supported. It should be set to "Initialize using input port <Y0>"',...
                    HtmlItem.addOpenCmd(blk.Origin_path));
                obj.addUnsupported_options(msg);
            end
            
            for i=1:numel(blk.IndexOptionArray)
                if strcmp(blk.IndexOptionArray{i}, 'Starting and ending indices (port)')
                    msg = sprintf('IndexOption  %s not supported in block %s',...
                        blk.IndexOptionArray{i}, HtmlItem.addOpenCmd(blk.Origin_path));
                    obj.addUnsupported_options(msg);
                end
            end
            options = obj.unsupported_options;
        end   
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
    end
    methods
        [in_matrix_dimension, U_expanded_dims,inputs] = expand_U(obj, parent,blk,inputs,numOutDims)
        [codes] = getWriteCodeForNonPortInput(obj, in_matrix_dimension,inputs,outputs,numOutDims,U_expanded_dims,ind)
        [codes] = getWriteCodeForPortInput(obj, in_matrix_dimension,inputs,outputs,numOutDims,U_expanded_dims,ind,blk)
    end
    methods(Static)
        in_matrix_dimension = getInputMatrixDimensions(inport_dimensions)
        [inputs] = getBlockInputsNames_convInType2AccType(obj, parent, blk,isSelector)
        [isPortIndex,ind,selectorOutputDimsArray] = defineMapInd(~,parent,blk,inputs,U_expanded_dims,isSelector)
    end
    
end

