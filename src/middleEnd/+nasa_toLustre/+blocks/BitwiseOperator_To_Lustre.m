classdef BitwiseOperator_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % BitwiseOperator_To_Lustre translates BitwiseOperator block to Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        function obj = BitwiseOperator_To_Lustre()
            obj.ContentNeedToBeTranslated = false;
        end
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            %% Step 1: Get the block outputs names
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            %% Step 2: add outputs_dt to the list of variables to be declared
            % in the var section of the node.
            obj.addVariable(outputs_dt);
            
            %% Step 3: construct the inputs names
            % we initialize the inputs by empty cell.
            
            widths = blk.CompiledPortWidths.Inport;
            numInputs = numel(widths);
            max_width = max(widths);
            % save the information of the outport dataType,
            inputDT = blk.CompiledPortDataTypes.Inport{1};
            inputs = cell(1, numInputs);
            % Go over inputs, numel(widths) is the number of inputs.
            for i=1:numInputs
                % fill the names of the ith input.
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
            end
            
            if strcmp(blk.UseBitMask, 'on')
                [bitMaskValue, ~, status] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent,...
                    blk, blk.BitMask);
                
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        blk.BitMask, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                        MsgType.ERROR, 'Constant_To_Lustre', '');
                    return;
                end
                max_width = max(max_width, numel(bitMaskValue));
                bitIndex = length(inputs) + 1;
                for i=1:numel(bitMaskValue)
                    inputs{bitIndex}{i} = nasa_toLustre.lustreAst.IntExpr(bitMaskValue(i));
                end
                numInputs = numInputs + 1;
            end
            % if an input has a width lesser than the max_width, we
            % need to make it equal to the max_width.
            for i=1:numInputs
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
            end
            %% Step 4: start filling the definition of each output
            if MatlabUtils.endsWith(inputDT, 'int8')
                intSize = 8;
            elseif MatlabUtils.endsWith(inputDT, 'int16')
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
            
            
            % Go over outputs
            if (strcmp(op, 'NAND') || strcmp(op, 'NOR'))...
                    && numInputs ~= 2
                new_op = op(2:end);%remove N from NAND and NOR
                new_fun = sprintf('_%s_Bitwise_%s_%d', new_op, signedStr, intSize);
                if signed
                    not_fun = sprintf('_NOT_Bitwise_%s', signedStr);
                else
                    not_fun = sprintf('_NOT_Bitwise_%s_%d', signedStr, intSize);
                end
                obj.addExternal_libraries(...
                    {strcat('LustMathLib_', new_fun), ...
                    strcat('LustMathLib_', not_fun)});
                for j=1:numel(outputs)
                    scalars = {};
                    if numInputs==1
                        for i=1:numel(inputs{1})
                            scalars{i} = inputs{1}{i};
                        end
                    else
                        for i=1:numInputs
                            scalars{i} = inputs{i}{j};
                        end
                    end
                    
                    res = nasa_toLustre.lustreAst.NodeCallExpr(not_fun, ...
                        nasa_toLustre.blocks.MinMax_To_Lustre.recursiveMinMax(new_fun, scalars));
                    codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, res);
                end
            else
                codes = cell(1, numel(outputs));
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
                    if strcmp(op, 'NOT')
                        res = nasa_toLustre.lustreAst.NodeCallExpr(fun, scalars);
                    else
                        res = nasa_toLustre.blocks.MinMax_To_Lustre.recursiveMinMax(fun, scalars);
                    end
                    
                    codes{j} =  nasa_toLustre.lustreAst.LustreEq(outputs{j}, res);
                end
                obj.addExternal_libraries(strcat('LustMathLib_', fun));
            end
            % join the lines and set the block code.
            obj.addCode( codes );
            
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

