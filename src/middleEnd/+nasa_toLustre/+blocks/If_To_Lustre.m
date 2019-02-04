classdef If_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % IF block generates boolean conditions that will be used with the
    % Action subsystems that are linked to.
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
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            
            [inputs, inports_dt] = If_To_Lustre.getInputs(parent, blk);
            % get all expressions
            IfExp = If_To_Lustre.getIfExp(blk);
            %% Step 4: start filling the definition of each output
            code = If_To_Lustre.ifElseCode(obj, parent, blk, outputs, ...
                inputs, inports_dt, IfExp);
            obj.setCode(code);
            
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            % add your unsuported options list here
            [inputs, inports_dt] = If_To_Lustre.getInputs(parent, blk);
            data_map = Fcn_To_Lustre.createDataMap(inputs, inports_dt);
            IfExp = If_To_Lustre.getIfExp(blk);
            nbOutputs=numel(blk.CompiledPortWidths.Outport);
            for j=1:nbOutputs
                [~, status] = If_To_Lustre.formatConditionToLustre(obj, ...
                    IfExp{j}, inputs, data_map, parent, blk);
                if status
                    obj.addUnsupported_options(sprintf('ParseError  character unsupported  %s in block %s', ...
                        IfExp{j}, HtmlItem.addOpenCmd(blk.Origin_path)));
                end
            end
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static)
        function [inputs, inports_dt] = getInputs(parent, blk)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            widths = blk.CompiledPortWidths.Inport;
            inputs = cell(1, numel(widths));
            inports_dt = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(i));
                inports_dt{i} = arrayfun(@(x) dt, (1:numel(inputs{i})), ...
                    'UniformOutput', false);
            end
        end
        function IfExp = getIfExp(blk)
            IfExp{1} =  blk.IfExpression;
            elseExp = split(blk.ElseIfExpressions, ',');
            IfExp = [IfExp; elseExp];
            if strcmp(blk.ShowElse, 'on')
                IfExp{end+1} = '';
            end
        end
        function code = ifElseCode(obj, parent, blk, outputs, inputs, inports_dt, IfExp)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            % Go over outputs
            nbOutputs=numel(outputs);
            if isempty(IfExp{nbOutputs})
                n_conds = nbOutputs - 1;
            else
                n_conds = nbOutputs;
            end
            thens = cell(1, n_conds + 1);
            conds = cell(1, n_conds);
            data_map = Fcn_To_Lustre.createDataMap(inputs, inports_dt);
            for j=1:nbOutputs
                lusCond = If_To_Lustre.formatConditionToLustre(obj, ...
                    IfExp{j}, inputs, data_map, parent, blk);
                if j==nbOutputs && isempty(IfExp{j})
                    %default condition
                    thens{j} = If_To_Lustre.outputsValues(nbOutputs, j);
                elseif j==nbOutputs
                    %last condition
                    conds{j} = lusCond;
                    thens{j} = If_To_Lustre.outputsValues(nbOutputs, j);
                    thens{j + 1} = If_To_Lustre.outputsValues(nbOutputs, 0);
                else
                    conds{j} = lusCond;
                    thens{j} = If_To_Lustre.outputsValues(nbOutputs, j);
                end
                
            end
            code = LustreEq(outputs, ...
                IteExpr.nestedIteExpr(conds, thens));
        end
        
        function exp  = outputsValues(outputsNumber, outputIdx)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            values = arrayfun(@(x) BooleanExpr('false'), (1:outputsNumber),...
                'UniformOutput', 0);
            if outputIdx > 0 && outputIdx <= outputsNumber
                values{outputIdx} = BooleanExpr('true');
            end
            exp = TupleExpr(values);
        end
        
        
        %% new version of parsing Lustre expression.
        function [exp, status] = formatConditionToLustre(obj, cond, inputs_cell, data_map, parent, blk)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            %display_msg(cond, MsgType.DEBUG, 'If_To_Lustre', '');
            expected_dt = 'bool';
            [exp, status] = ...
                MExpToLusAST.translate(obj, cond, parent, blk,data_map, inputs_cell, expected_dt, true, false);
            if iscell(exp) 
                if numel(exp) == 1
                    exp = exp{1};
                elseif numel(exp) > 1
                    exp = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, exp);
                end
            end
            if status
                display_msg(sprintf('Block %s is not supported', HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'If_To_Lustre.formatConditionToLustre', '');
                return;
            end
        end
        
        
    end
    
end

