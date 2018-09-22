classdef If_To_Lustre < Block_To_Lustre
    % IF block generates boolean conditions that will be used with the
    % Action subsystems that are linked to.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        % needed for Fcn_To_Lustre.tree2code
        isBooleanExpr = 1;
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
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
            % add your unsuported options list here
            [inputs, inports_dt] = If_To_Lustre.getInputs(parent, blk);
            IfExp = If_To_Lustre.getIfExp(blk);
            nbOutputs=numel(blk.CompiledPortWidths.Outport);
            for j=1:nbOutputs
                [tree, status, unsupportedExp] = Fcn_Exp_Parser(IfExp{j});
                if status
                    obj.addUnsupported_options(sprintf('ParseError  character unsupported  %s in block %s', ...
                        unsupportedExp, blk.Origin_path));
                end
                try
                    Fcn_To_Lustre.tree2code(obj, tree, parent, blk, inputs, inports_dt{1});
                catch me
                    if strcmp(me.identifier, 'COCOSIM:TREE2CODE')
                        obj.addUnsupported_options(me.message);
                    end
                end
            end
            options = obj.getUnsupportedOptions();
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static)
        function [inputs, inports_dt] = getInputs(parent, blk)
            widths = blk.CompiledPortWidths.Inport;
            inputs = cell(1, numel(widths));
            inports_dt = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                inports_dt{i} = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(i));
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
            % Go over outputs
            nbOutputs=numel(outputs);
            if isempty(IfExp{nbOutputs})
                n_conds = nbOutputs - 1;
            else
                n_conds = nbOutputs;
            end
            thens = cell(1, n_conds + 1);
            conds = cell(1, n_conds);
            for j=1:nbOutputs
                lusCond = If_To_Lustre.formatConditionToLustre(obj, ...
                    IfExp{j}, inputs, inports_dt, parent, blk);
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
            values = arrayfun(@(x) BooleanExpr('false'), (1:outputsNumber),...
                'UniformOutput', 0);
            if outputIdx > 0 && outputIdx <= outputsNumber
                values{outputIdx} = BooleanExpr('true');
            end
            exp = TupleExpr(values);
        end
        
        
        %% new version of parsing Lustre expression.
        function exp = formatConditionToLustre(obj, cond, inputs_cell, inputs_dt, parent, blk)
            %display_msg(cond, MsgType.DEBUG, 'If_To_Lustre', '');
            exp = VarIdExpr('');
            [tree, status, unsupportedExp] = Fcn_Exp_Parser(cond);
            if status
                display_msg(sprintf('ParseError  character unsupported  %s in block %s', ...
                    unsupportedExp, blk.Origin_path), ...
                    MsgType.ERROR, 'IF_To_Lustre', '');
                return;
            end
            try
                exp = Fcn_To_Lustre.tree2code(obj, tree, parent, blk, inputs_cell, inputs_dt{1});
            catch me
                if strcmp(me.identifier, 'COCOSIM:TREE2CODE')
                    display_msg(me.message, ...
                        MsgType.ERROR, 'IF_To_Lustre', '');
                end
            end
        end
        
        
    end
    
end

