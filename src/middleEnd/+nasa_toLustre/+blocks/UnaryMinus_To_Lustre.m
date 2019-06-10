classdef UnaryMinus_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % UnaryMinus_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            
            %% Step 1: Get the block outputs names,
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
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
            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport(1);
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            %converts the input data type(s) to the output datatype
            if ~strcmp(inport_dt, outputDataType)
                [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, [], SaturateOnIntegerOverflow);
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                    inputs{1} = cellfun(@(x) ...
                       nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x), inputs{1}, 'un', 0);
                end
            end
            
            
            %% Step 4: start filling the definition of each output
            codes = cell(1, numel(outputs));
            isSignedInt = true;
            if strcmp(inport_dt, 'int8')
                vmin = nasa_toLustre.lustreAst.IntExpr(-128);
                vmax = nasa_toLustre.lustreAst.IntExpr(127);
            elseif strcmp(inport_dt, 'int16')
                vmin = nasa_toLustre.lustreAst.IntExpr(-32768);
                vmax = nasa_toLustre.lustreAst.IntExpr(32767);
            elseif strcmp(inport_dt, 'int32')
                vmin = nasa_toLustre.lustreAst.IntExpr(-2147483648);
                vmax = nasa_toLustre.lustreAst.IntExpr(2147483647);
            else
                isSignedInt = false;
            end
            if isSignedInt
                if strcmp(SaturateOnIntegerOverflow, 'off')
                    vmax = vmin;
                end
                % Go over outputs
                for j=1:numel(outputs)
                    codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, ...
                        nasa_toLustre.lustreAst.IteExpr(...
                                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
                                           inputs{1}{j}, ...
                                           vmin), ...
                                 vmax, ...
                                 nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, inputs{1}{j})));
                    
                end
            else
                % Go over outputs
                for j=1:numel(outputs)
                    codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, ...
                         nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, inputs{1}{j}));
                end
            end
            
            obj.addCode( codes );
            
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

