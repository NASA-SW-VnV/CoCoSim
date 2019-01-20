classdef UnaryMinus_To_Lustre < Block_To_Lustre
    % UnaryMinus_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            %% Step 1: Get the block outputs names,
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            %% Step 2: add outputs_dt to the list of variables to be declared
            % in the var section of the node.
            obj.addVariable(outputs_dt);
            
            %% Step 3: construct the inputs names,
            
            % we initialize the inputs by empty cell.
            inputs = {};
            
            % save the information of the outport dataType,
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            % fill the names of the ith input.
            % inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
            inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport(1);
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            %converts the input data type(s) to the output datatype, if
            %needed. If we have a product of double with int, the
            %output will be double, so we need to cast the int input to
            %double.
            if ~strcmp(inport_dt, outputDataType)
                % this function return if a casting is needed
                % "conv_format", a library or the name of casting node
                % will be stored in "external_lib".
                [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, [], SaturateOnIntegerOverflow);
                if ~isempty(conv_format)
                    % always add the "external_lib" to the object
                    % external libraries, (so it can be declared in the
                    % overall lustre code).
                    obj.addExternal_libraries(external_lib);
                    % cast the input to the conversion format. In our
                    % example conv_format = 'int_to_real(%s)'.
                    inputs{1} = cellfun(@(x) ...
                        SLX2LusUtils.setArgInConvFormat(conv_format,x), inputs{1}, 'un', 0);
                end
            end
            
            
            %% Step 4: start filling the definition of each output
            codes = cell(1, numel(outputs));
            isSignedInt = true;
            if strcmp(inport_dt, 'int8')
                vmin = IntExpr(-128);
                vmax = IntExpr(127);
            elseif strcmp(inport_dt, 'int16')
                vmin = IntExpr(-32768);
                vmax = IntExpr(32767);
            elseif strcmp(inport_dt, 'int32')
                vmin = IntExpr(-2147483648);
                vmax = IntExpr(2147483647);
            else
                isSignedInt = false;
            end
            if isSignedInt
                if strcmp(SaturateOnIntegerOverflow, 'off')
                    vmax = vmin;
                end
                % Go over outputs
                for j=1:numel(outputs)
                    % example of lement wise product block.
                    codes{j} = LustreEq(outputs{j}, ...
                        IteExpr(...
                                BinaryExpr(BinaryExpr.EQ, ...
                                           inputs{1}{j}, ...
                                           vmin), ...
                                 vmax, ...
                                 UnaryExpr(UnaryExpr.NEG, inputs{1}{j})));
                    
                end
            else
                % Go over outputs
                for j=1:numel(outputs)
                    % example of lement wise product block.
                    codes{j} = LustreEq(outputs{j}, ...
                         UnaryExpr(UnaryExpr.NEG, inputs{1}{j}));
                end
            end
            
            obj.setCode( codes );
            
        end
        %%
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

