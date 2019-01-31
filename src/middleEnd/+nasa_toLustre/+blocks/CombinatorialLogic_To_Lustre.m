classdef CombinatorialLogic_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
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
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            %% Step 1: Get the block outputs names,
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            %% Step 2: add outputs_dt to the list of variables to be declared
            % in the var section of the node.
            obj.addVariable(outputs_dt);
            
            %% Step 3: construct the inputs names,
            
            % save the information of the outport dataType,
            outputLusDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport{1});
            inport_dt = blk.CompiledPortDataTypes.Inport(1);
            lusInport_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            
            % change booleans to int, so we can calculate the row index
            % equation.
            if ~strcmp(lusInport_dt, 'int')
                % this function return if a casting is needed
                % "conv_format", a library or the name of casting node
                % will be stored in "external_lib".
                [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'int');
                if ~isempty(conv_format)
                    % always add the "external_lib" to the object
                    % external libraries, (so it can be declared in the
                    % overall lustre code).
                    obj.addExternal_libraries(external_lib);
                    % cast the input to the conversion format. In our
                    % example conv_format = 'int_to_real(%s)'.
                    inputs{1} = cellfun(@(x) ...
                       nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x), ...
                        inputs{1}, 'un', 0);
                end
            end
            
            
            %% Step 4: start filling the definition of each output
            codes = cell(1, numel(outputs) + 1 );
            % define row index
            %row index = 1 + u(m)*2^0 + u(m-1)*2^1 + ... + u(1)*2^(m-1)
            blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            row_index_varName = sprintf('row_index_%s', blk_name);
            obj.addVariable( LustreVar(row_index_varName, 'int'));
            
            m = numel(inputs{1});
            row_term = cell(1, m + 1);
            for i=0:m-1
                v = 2^i;
                row_term{i+1} = BinaryExpr(BinaryExpr.MULTIPLY, ...
                    inputs{1}{m-i}, IntExpr(v));
                %sprintf('%s * %d', inputs{1}{m-i}, v);
            end
            row_term{m + 1} = IntExpr(1); 
            codes{1} = LustreEq(VarIdExpr(row_index_varName), ...
                BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, row_term));
            %sprintf('%s = 1 + %s;\n\t', ...
            %        row_index_varName, MatlabUtils.strjoin(row_term, ' + '));
                
            [truthTable, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.TruthTable);
            [nbRow, ~] = size(truthTable);
            % Go over outputs
            for j=1:numel(outputs)
                conds = cell(1, nbRow - 1);
                thens = cell(1, nbRow );
                for i=1:nbRow-1
                    v_lus = CombinatorialLogic_To_Lustre.getAstValue(truthTable(i,j), outputLusDT);
                    conds{i} = BinaryExpr(BinaryExpr.EQ, ...
                        VarIdExpr(row_index_varName), IntExpr(i));
                    thens{i} = v_lus;
                    %sprintf('if %s = %d then %s\n\t\telse ', row_index_varName, i, v_str);
                end
                % last row
                v_lus = CombinatorialLogic_To_Lustre.getAstValue(truthTable(nbRow,j), outputLusDT);
                thens{nbRow} = v_lus;
                rightCode = IteExpr.nestedIteExpr(conds, thens);
                % example of lement wise product block.
                codes{j+1} = LustreEq(outputs{j}, rightCode);
            end
            % join the lines and set the block code.
            obj.setCode( codes );
            
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static)
        
        function v_lus = getAstValue(v, dt)
            % in this block, the output dataType is Boolean or double
            if strcmp(dt, 'bool')
                v_lus = BooleanExpr(v);
            else
                v_lus = RealExpr(v);
            end
            
        end
    end
    
end

