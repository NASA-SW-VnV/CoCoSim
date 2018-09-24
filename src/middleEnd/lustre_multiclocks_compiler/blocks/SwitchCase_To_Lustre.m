classdef SwitchCase_To_Lustre < Block_To_Lustre
    % SwitchCase block generates boolean conditions that will be used with the
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
            
           [inputs, inports_dt] = obj.getInputs( parent, blk);
            % get all conditions expressions
            IfExp = obj.getIfExp(blk);
            %% Step 4: start filling the definition of each output
            code = If_To_Lustre.ifElseCode(obj, parent, blk, outputs, ...
                inputs, inports_dt, IfExp);
            obj.setCode( code );
            
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            [inputs, inports_dt] = obj.getInputs( parent, blk);
            IfExp = obj.getIfExp(blk);
            nbOutputs = numel(blk.CompiledPortWidths.Outport);
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
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        %%
        function IfExp = getIfExp(obj, blk)
            CaseConditions = eval(blk.CaseConditions);
            IfExp = cell(1, numel(CaseConditions));
            for i=1:numel(CaseConditions)
                if numel(CaseConditions{i}) == 1
                    IfExp{i} = sprintf('u1 == %d', CaseConditions{i});
                else
                    exp = cell(1, numel(CaseConditions{i}));
                    for j=1:numel(CaseConditions{i})
                        exp{j} = sprintf('u1 == %d', CaseConditions{i}(j));
                    end
                    IfExp{i} = MatlabUtils.strjoin(exp, ' | ');
                end
                
            end
            if strcmp(blk.ShowDefaultCase, 'on')
                IfExp{end+1} = '';
            end
        end
        %%
        function [inputs, inports_dt] = getInputs(obj, parent, blk)
             % take the list of the inputs width, in the previous example,
            % "In1" has a width of 3 and "In2" has a width of 1.
            % So width = [3, 1].
            widths = blk.CompiledPortWidths.Inport;
            % Go over inputs, numel(widths) is the number of inputs. In
            % this example is 2 ("In1", "In2").
            inputs = cell(1, numel(widths));
            inports_dt = cell(1, numel(widths));
            for i=1:numel(widths)
                % fill the names of the ith input.
                % inputs{1} = {'In1_1', 'In1_2', 'In1_3'}
                % and inputs{2} = {'In2_1'}
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                inports_dt{i} = SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(i));
                if ~strcmp(inports_dt{i}, 'int')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inports_dt{i}, 'int');
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x), inputs{i}, 'un', 0);
                    end
                    inports_dt{i} = 'int';
                end
            end
        end
    end
    
    
    
end

