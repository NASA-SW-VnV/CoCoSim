classdef Trigonometry_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Abs_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk,xml_trace,  varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            obj.addExternal_libraries('LustMathLib_lustrec_math');
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            inputs = cell(1, nbInputs);
            for i=1:nbInputs
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, 'real')
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'real');
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end
            
            operator = blk.Operator;
            
            unsupportedOp = {'cos + jsin'};
            if ismember(operator, unsupportedOp)
                display_msg(sprintf('The "%s" operator is not supported in block %s',...
                    operator, HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'Trigonometry_To_Lustre', '');
                return;
            elseif strcmp(operator, 'sincos')
                index = 0;
                codes = cell(1, 2*widths);
                for i=1:widths
                    index = index + 1;
                    operator = 'sin';
                    codes{index} = LustreEq(outputs{index}, ...
                        NodeCallExpr(operator, inputs{1}{i}));
                end
                for i=1:widths
                    index = index + 1;
                    operator = 'cos';
                    codes{index} = LustreEq(outputs{index}, ...
                        NodeCallExpr(operator, inputs{1}{i}));
                end
            elseif strcmp(operator, 'atan2')
                codes = cell(1, numel(outputs));
                for i=1:numel(outputs)
                    codes{i} = LustreEq(outputs{i}, ...
                        NodeCallExpr(operator, ...
                        {inputs{1}{i}, inputs{2}{i}}));
                end
            else
                codes = cell(1, numel(outputs));
                for i=1:numel(outputs)
                    codes{i} = LustreEq(outputs{i}, ...
                        NodeCallExpr(operator, inputs{1}{i}));
                end
            end
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        %%
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            unsupportedOp = {'cos + jsin'};
            if ismember(blk.Operator, unsupportedOp)
                obj.addUnsupported_options(...
                    sprintf('The "%s" option is not supported in block %s', blk.Operator, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
           
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(~, lus_backend, varargin)
            is_Abstracted = LusBackendType.isKIND2(lus_backend);
        end
    end
    
end

