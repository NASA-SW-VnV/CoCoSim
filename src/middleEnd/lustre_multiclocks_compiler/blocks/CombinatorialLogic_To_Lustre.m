classdef CombinatorialLogic_To_Lustre < Block_To_Lustre
    %CombinatorialLogic_To_Lustre
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
            %% Step 1: Get the block outputs names,
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk);
            
            %% Step 2: add outputs_dt to the list of variables to be declared
            % in the var section of the node.
            obj.addVariable(outputs_dt);
            
            %% Step 3: construct the inputs names,
            
            % save the information of the outport dataType,
            outputLusDT = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport{1});
            inport_dt = blk.CompiledPortDataTypes.Inport(1);
            lusInport_dt = SLX2LusUtils.get_lustre_dt(inport_dt);
            inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            
            % change booleans to int, so we can calculate the row index
            % equation.
            if ~strcmp(lusInport_dt, 'int')
                % this function return if a casting is needed
                % "conv_format", a library or the name of casting node
                % will be stored in "external_lib".
                [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'int');
                if ~isempty(external_lib)
                    % always add the "external_lib" to the object
                    % external libraries, (so it can be declared in the
                    % overall lustre code).
                    obj.addExternal_libraries(external_lib);
                    % cast the input to the conversion format. In our
                    % example conv_format = 'int_to_real(%s)'.
                    inputs{1} = cellfun(@(x) sprintf(conv_format,x), inputs{1}, 'un', 0);
                end
            end
            
            
            %% Step 4: start filling the definition of each output
            codes = {};
            % define row index
            %row index = 1 + u(m)*2^0 + u(m-1)*2^1 + ... + u(1)*2^(m-1)
            blk_name = SLX2LusUtils.node_name_format(blk);
            row_index_varName = sprintf('row_index_%s', blk_name);
            obj.addVariable( sprintf('%s:int;', row_index_varName));
            row_term = {};
            m = numel(inputs{1});
            for i=0:m-1
                v = 2^i;
                row_term{i+1} = sprintf('%s * %d', inputs{1}{m-i}, v);
            end
            codes{1} = sprintf('%s = 1 + %s;\n\t', ...
                    row_index_varName, MatlabUtils.strjoin(row_term, ' + '));
                
            [truthTable, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.TruthTable);
            [nbRow, ~] = size(truthTable);
            % Go over outputs
            for j=1:numel(outputs)
                rightCode = {};
                for i=1:nbRow-1
                    v_str = CombinatorialLogic_To_Lustre.getStrValue(truthTable(i,j), outputLusDT);
                    rightCode{i} = sprintf('if %s = %d then %s\n\t\telse ', row_index_varName, i, v_str);
                end
                % last row
                v_str = CombinatorialLogic_To_Lustre.getStrValue(truthTable(nbRow,j), outputLusDT);
                rightCode{nbRow} = sprintf('%s', v_str);
                rightCode = MatlabUtils.strjoin(rightCode, '');
                % example of lement wise product block.
                codes{end+1} = sprintf('%s = %s;\n\t', ...
                    outputs{j}, rightCode);
            end
            % join the lines and set the block code.
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
    end
    methods(Static)
        
        function v_str = getStrValue(v, dt)
            % in this block, the output dataType is Boolean or double
            if strcmp(dt, 'bool')
                if v
                    v_str = 'true';
                else
                    v_str = 'false';
                end
            else
                v_str = sprintf('%.15f', v);
            end
            
        end
    end
    
end

