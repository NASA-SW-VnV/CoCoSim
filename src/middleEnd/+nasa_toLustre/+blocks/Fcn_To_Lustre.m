classdef Fcn_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Fcn_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        
        function  status = write_code(obj, parent, blk, xml_trace, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            if isempty(xml_trace)
                %comming from getUnsupportedOptions
                [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk);
            else
                [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            end
            
            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            
            inputs_dt{1} = arrayfun(@(x) 'real', (1:numel(inputs{1})), ...
                'UniformOutput', false);
            
            data_map = Fcn_To_Lustre.createDataMap(inputs, inputs_dt);
            
            expected_dt = 'real';
            
            [lusCode, status] = ...
                MExpToLusAST.translate(obj, blk.Expr, parent, blk, data_map, inputs, expected_dt, true, false);
            
            if status
                display_msg(sprintf('Block %s is not supported', HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Fcn_To_Lustre.write_code', '');
                return;
            end
            
           
            obj.setCode(LustreEq(outputs{1}, lusCode{1}));
            obj.addVariable(outputs_dt);
            
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            % calling write_code because this block manipulate Expressions.
            status = obj.write_code(parent, blk, [], varargin);
            if status
                obj.addUnsupported_options(sprintf('ParseError  character unsupported  %s in block %s', ...
                    blk.Expr, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static)
        function data_map = createDataMap(inputs, inputs_dt)
            data_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
            for i=1:numel(inputs)
                for j=1:numel(inputs{i})
                    data_map(inputs{i}{j}.getId()) = inputs_dt{i}{j};
                end
            end
        end
    end
end

