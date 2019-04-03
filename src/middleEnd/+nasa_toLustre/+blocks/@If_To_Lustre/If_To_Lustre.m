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
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            
            [inputs, inports_dt] = nasa_toLustre.blocks.If_To_Lustre.getInputs(parent, blk);
            % get all expressions
            IfExp = nasa_toLustre.blocks.If_To_Lustre.getIfExp(blk);
            %% Step 4: start filling the definition of each output
            code = nasa_toLustre.blocks.If_To_Lustre.ifElseCode(obj, parent, blk, outputs, ...
                inputs, inports_dt, IfExp);
            obj.addCode(code);
            
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            % add your unsuported options list here
            [inputs, inports_dt] = nasa_toLustre.blocks.If_To_Lustre.getInputs(parent, blk);
            data_map = nasa_toLustre.blocks.Fcn_To_Lustre.createDataMap(inputs, inports_dt);
            IfExp = nasa_toLustre.blocks.If_To_Lustre.getIfExp(blk);
            nbOutputs=numel(blk.CompiledPortWidths.Outport);
            for j=1:nbOutputs
                [~, status] = nasa_toLustre.blocks.If_To_Lustre.formatConditionToLustre(obj, ...
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
        [inputs, inports_dt] = getInputs(parent, blk)

        IfExp = getIfExp(blk)

        code = ifElseCode(obj, parent, blk, outputs, inputs, inports_dt, IfExp)
        
        exp  = outputsValues(outputsNumber, outputIdx)
                
        %% new version of parsing Lustre expression.
        [exp, status] = formatConditionToLustre(obj, cond, inputs_cell, data_map, parent, blk)

    end
    
end

