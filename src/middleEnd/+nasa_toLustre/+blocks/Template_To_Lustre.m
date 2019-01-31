classdef Template_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % This is a template for the user to follow for developping a specific
    % block to Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, main_sampletime, varargin)
            %% Step 0: Import all functions in nasa_toLustre package
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            %% Step 1: Get the block outputs names, If a block is called X
            % and has one outport with width 3 and datatype double,
            % then outputs = {'X_1', 'X_2', 'X_3'}
            % and outputs_dt = {'X_1:real;', 'X_2:real;', 'X_3:real;'}
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            %% Step 2: add outputs_dt to the list of variables to be declared
            % in the var section of the node.
            obj.addVariable(outputs_dt);
            
            %% Step 3: construct the inputs names, if a block "X" has two inputs,
            % ("In1" and "In2")
            % "In1" is of dimension 3 and "In2" is of dimension 1.
            % Then inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
            % and inputs{2} = {'In2_1'}
            
            % we initialize the inputs by empty cell.
            
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
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            % Go over inputs, numel(widths) is the number of inputs. In
            % this example is 2 ("In1", "In2").
            inputs = cell(1, numel(widths));
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
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        % always add the "external_lib" to the object
                        % external libraries, (so it can be declared in the
                        % overall lustre code).
                        obj.addExternal_libraries(external_lib);
                        % cast the input to the conversion format. In our
                        % example conv_format = 'int_to_real(%s)'.
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            
            %% Step 4: start filling the definition of each output
            nb_outputs = numel ( outputs );
            codes = cell (1, nb_outputs);
            
            % Go over outputs
            for j=1:nb_outputs
                % example:
                % out_1 = in1_1 / in2_1;
                % out_2 = in1_2 / in2_2;
                % ....
                % out_n = in1_n / in2_n;
                codes{j} = LustreEq(outputs{j},...
                    BinaryExpr(BinaryExpr.DIVIDE,...
                    inputs{1}{j}, inputs{2}{j}));
            end
            
            %% Step 5: If the backend is Design Error Detection (DED).
            % If the backend is DED, copy this template and adapt it to the
            % block in question
            if CoCoBackendType.isDED(coco_backend)
                global  CoCoSimPreferences;% remember to move this line to top-level statement
                blk_name = SLX2LusUtils.node_name_format(blk);
                
                if ismember(CoCoBackendType.DED_DIVBYZER, ...
                        CoCoSimPreferences.dedChecks)
                    % Add properties related to Division by zero, if the
                    % block has no division, ignore this check.
                    
                    % example:
                    % choose the correct zero: Int or Real
                    inport_dt = blk.CompiledPortDataTypes.Inport(2);
                    lus_dt = SLX2LusUtils.get_lustre_dt(inport_dt);
                    if isequal(lus_dt, 'int')
                        zero = IntExpr(0);
                    else
                        zero = RealExpr(0);
                    end
                    prop1 = {};
                    for i=1:numel(inputs{2})
                        % set the property
                        % denominator <> 0.0;
                        prop1{i} = BinaryExpr(BinaryExpr.NEQ, inputs{2}{i}, zero);
                    end
                    propID = sprintf('%s_DIVBYZERO',blk_name);
                    codes{end+1} = LocalPropertyExpr(propID, ...
                        BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, prop1));
                    % add traceability:
                    parent_name = SLX2LusUtils.node_name_format(parent);
                    xml_trace.add_Property(blk.Origin_path, ...
                        parent_name, propID, 1, ...
                        CoCoBackendType.DED_DIVBYZER);
                end
                if ismember(CoCoBackendType.DED_INTOVERFLOW, ...
                        CoCoSimPreferences.dedChecks)
                    % Add properties related to Integer Overflow. Ignore
                    % the check if it is not related to the block in
                    % question.
                    % example:
                    
                    % detect the right output datatype : int8, int16,
                    % int32...
                    lus_dt = SLX2LusUtils.get_lustre_dt(outputDataType);
                    if isequal(lus_dt, 'int')
                        % calculate intMin intMax
                        intMin = IntExpr(intmin(outputDataType));
                        intMax = IntExpr(intmax(outputDataType));
                        % set the property
                        prop2 = {};
                        for j=1:nb_outputs
                            % Lustre int is a BigInt: detecting integer overflow
                            % can be easily be expressed as:
                            % intMin <= out and out <= intMax
                            prop2{j} = BinaryExpr(BinaryExpr.AND, ...
                                BinaryExpr(BinaryExpr.LTE, intMin, outputs{j}), ...
                                BinaryExpr(BinaryExpr.LTE, outputs{j}, intMax));
                        end
                        propID = sprintf('%s_INTOVERFLOW',blk_name);
                        codes{end+1} = LocalPropertyExpr(propID, ...
                            BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, prop2));
                        % add traceability:
                        parent_name = SLX2LusUtils.node_name_format(parent);
                        xml_trace.add_Property(blk.Origin_path, ...
                            parent_name, propID, 1, ...
                            CoCoBackendType.DED_INTOVERFLOW);
                    end
                end
                if ismember(CoCoBackendType.DED_OUTOFBOUND, ...
                        CoCoSimPreferences.dedChecks)
                    % Add properties related to Out of bound array access.
                    % Ignore the check if it is not related to the block in
                    % question.
                    % example:
                    propID = sprintf('%s_OUTOFBOUND',blk_name);
                    prop = DEDUtils.OutOfBoundCheck(inputs{2}, widths(2));
                    codes{end+1} = LocalPropertyExpr(propID, prop);
                    % add traceability:
                    parent_name = SLX2LusUtils.node_name_format(parent);
                    xml_trace.add_Property(blk.Origin_path, ...
                        parent_name, propID, 1, ...
                        CoCoBackendType.DED_OUTOFBOUND);
                end
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    % Add properties related to minimum and maximum values check.
                    % Ignore the check if it is not related to the block in
                    % question.
                    lus_dt = SLX2LusUtils.get_lustre_dt(outputDataType);
                    prop = DEDUtils.OutMinMaxCheck(parent, blk, outputs, lus_dt);
                    if ~isempty(prop)
                        propID = sprintf('%s_OUTMINMAX',blk_name);
                        codes{end+1} = LocalPropertyExpr(propID, prop);
                        % add traceability:
                        parent_name = SLX2LusUtils.node_name_format(parent);
                        xml_trace.add_Property(blk.Origin_path, ...
                            parent_name, propID, 1, ...
                            CoCoBackendType.DED_OUTMINMAX);
                    end
                end
            end
            %% Step 6: set the block code.
            obj.setCode( codes );
            
        end
        %%
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

