classdef SwitchCase_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % SwitchCase block generates boolean conditions that will be used with the
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
            %% Step 1: Get the block outputs names, If a block is called X
            % and has one outport with width 3 and datatype double,
            % then outputs = {'X_1', 'X_2', 'X_3'}
            % and outputs_dt = {'X_1:real;', 'X_2:real;', 'X_3:real;'}
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
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
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [inputs, inports_dt] = obj.getInputs( parent, blk);
            data_map = Fcn_To_Lustre.createDataMap(inputs, inports_dt);
            IfExp = obj.getIfExp(blk);
            nbOutputs = numel(blk.CompiledPortWidths.Outport);
            for j=1:nbOutputs
                [~, status] = If_To_Lustre.formatConditionToLustre(obj, ...
                    IfExp{j}, inputs, data_map, parent, blk);
                if status
                    obj.addUnsupported_options(sprintf('ParseError  character unsupported  %s in block %s', ...
                        unsupportedExp, HtmlItem.addOpenCmd(blk.Origin_path)));
                end
            end
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        %%
        IfExp = getIfExp(obj, blk)

        %%
        [inputs, inports_dt] = getInputs(obj, parent, blk)

    end
    
    
    
end

