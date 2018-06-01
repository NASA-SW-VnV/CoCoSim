classdef BitwiseOperator_To_Lustre < Block_To_Lustre
    % BitwiseOperator_To_Lustre translates BitwiseOperator block to Lustre
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
            %% Step 1: Get the block outputs names
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk);
            
            %% Step 2: add outputs_dt to the list of variables to be declared
            % in the var section of the node.
            obj.addVariable(outputs_dt);
            
            %% Step 3: construct the inputs names
            % we initialize the inputs by empty cell.
            inputs = {};
            widths = blk.CompiledPortWidths.Inport;
            numInputs = numel(widths);
            max_width = max(widths);
            % save the information of the outport dataType,
            inputDT = blk.CompiledPortDataTypes.Inport{1};
            
            % Go over inputs, numel(widths) is the number of inputs.
            for i=1:numInputs
                % fill the names of the ith input.
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                % if an input has a width lesser than the max_width, we
                % need to make it equal to the max_width.
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
            end
            if strcmp(blk.UseBitMask, 'on')
                inputs{end+1} = {sprintf('%d',eval(blk.BitMask))};
                if numel(inputs{end}) < max_width
                    inputs{end} = arrayfun(@(x) {inputs{end}{1}}, (1:max_width));
                end
                numInputs = numInputs + 1;
            end
            %% Step 4: start filling the definition of each output
            if endsWith(inputDT, 'int8')
                intSize = 8;
            elseif endsWith(inputDT, 'int16')
                intSize = 16;
            else
                intSize = 32;
            end
            signed = true;
            signedStr = 'Signed';
            if startsWith(inputDT, 'uint')
                signed = false;
                signedStr = 'Unsigned';
            end
            op = blk.logicop;
            if strcmp(op, 'NOT') && signed
                fun = sprintf('_%s_Bitwise_%s', op, signedStr);
            else
                fun = sprintf('_%s_Bitwise_%s_%d', op, signedStr, intSize);
            end
            
            codes = {};
            % Go over outputs
            if (strcmp(op, 'NAND') || strcmp(op, 'NOR'))...
                    && numInputs==1
                new_op = op(2:end);%remove N from NAND and NOR
                scalars = {};
                for i=1:numel(inputs{1})
                    scalars{i} = inputs{1}{i};
                end
                new_fun = sprintf('_%s_Bitwise_%s_%d', new_op, signedStr, intSize);
                if signed
                    not_fun = sprintf('_NOT_Bitwise_%s', signedStr);
                else
                    not_fun = sprintf('_NOT_Bitwise_%s_%d', signedStr, intSize);
                end
                obj.addExternal_libraries(new_fun);
                obj.addExternal_libraries(not_fun);
                res =sprintf('%s(%s)', ...
                    not_fun, MinMax_To_Lustre.recursiveMinMax(scalars, new_fun));
                codes{1} = sprintf('%s = %s;\n\t', ...
                        outputs{1}, res);
            else
                for j=1:numel(outputs)
                    scalars = {};
                    if numInputs==1
                        if strcmp(op, 'NOT')
                            scalars{1} = inputs{1}{j};
                        else
                            for i=1:numel(inputs{1})
                                scalars{i} = inputs{1}{i};
                            end
                        end
                    else
                        for i=1:numInputs
                            scalars{i} = inputs{i}{j};
                        end
                    end
                    res = MinMax_To_Lustre.recursiveMinMax(scalars, fun);
                    codes{j} = sprintf('%s = %s;\n\t', ...
                        outputs{j}, res);
                end
                obj.addExternal_libraries(fun);
            end
            % join the lines and set the block code.
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
    end
    
end

