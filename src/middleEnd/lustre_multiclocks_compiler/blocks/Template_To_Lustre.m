classdef Template_To_Lustre < Block_To_Lustre
    % This is a template for the user to follow for developping a block to
    % Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            %% Step 1: Get the block outputs names, If a block is called X
            % and has one outport with width 3 and datatype double, 
            % then outputs = {'X_1', 'X_2', 'X_3'}
            % and outputs_dt = {'X_1:real;', 'X_2:real;', 'X_3:real;'}
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            
            %% Step 2: add outputs_dt to the list of variables to be declared
            % in the var section of the node.
            obj.addVariable(outputs_dt);
            
            %% Step 3: construct the inputs names, if a block "X" has two inputs,
            % ("In1" and "In2")
            % "In1" is of dimension 3 and "In2" is of dimension 1.
            % Then inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
            % and inputs{2} = {'In2_1'}
            
            % we initialize the inputs by empty cell.
            inputs = {};
            % take the list of the inputs width, in the previous example,
            % "In1" has a width of 3 and "In2" has a width of 1. 
            % So width = [3, 1].
            widths = blk.CompiledPortWidths.Inport;
            % Max width in our example is 3.
            max_width = max(widths);
            % save the information of the outport dataType, here in this
            % example we assume "X" has only one outport.
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            % If "X" has a rounding method, it should be saved.
            RndMeth = blk.RndMeth;
            % Go over inputs, numel(widths) is the number of inputs. In
            % this example is 2 ("In1", "In2").
            for i=1:numel(widths)
                % fill the names of the ith input.
                % inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
                % and inputs{2} = {'In2_1'}
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                
                % if an input has a width lesser than the max_width, we
                % need to make it equal to the max_width. This is the case
                % of product block for example, multiplying a scalar with a
                % vector. We will change the scalar to a vector of the same
                % width.
                % in the end we will have something like
                % inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
                % and inputs{2} = {'In2_1', 'In2_1', 'In2_1'}
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                
                % Get the input datatype
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                
                %converts the input data type(s) to the output datatype, if
                %needed. If we have a product of double with int, the
                %output will be double, so we need to cast the int input to
                %double.
                if ~strcmp(inport_dt, outputDataType)
                    % this function return if a casting is needed
                    % "conv_format", a library or the name of casting node
                    % will be stored in "external_lib".
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth);
                    if ~isempty(external_lib)
                        % always add the "external_lib" to the object
                        % external libraries, (so it can be declared in the
                        % overall lustre code).
                        obj.addExternal_libraries(external_lib);
                        % cast the input to the conversion format. In our
                        % example conv_format = 'int_to_real(%s)'. 
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            
            %% Step 4: start filling the definition of each output
            codes = {};
            % Go over outputs
            for j=1:numel(outputs)
                % example of lement wise product block.
                codes{j} = sprintf('%s = %s * %s;\n\t', ...
                    outputs{j}, inputs{1}{j}, inputs{2}{j});
            end
            % join the lines and set the block code.
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
        end
        
        function options = getUnsupportedOptions(obj,blk, varargin)
            % add your unsuported options list here
           options = obj.unsupported_options;
           
        end
    end
    
end

