classdef Sqrt_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Sqrt_To_Lustre:
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        
    end
    
    methods
        function  write_code(obj, parent, blk, xml_trace, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                display_msg(sprintf('The minimum/maximum value is not support in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.WARNING, 'Sqrt_To_Lustre', '');
            end
            if strcmp(blk.AlgorithmType, 'Newton-Raphson')
                msg = sprintf('Option Newton-Raphson is not supported in block %s. Exact method will be used.', ...
                    HtmlItem.addOpenCmd(blk.Origin_path));
                display_msg(msg, MsgType.WARNING, 'Sqrt_To_Lustre', '');
            end

            obj.addExternal_libraries('LustMathLib_lustrec_math');
            
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, 'double')
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'double', RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            [outLusDT, zero, one] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            
            codes = cell(1, numel(inputs{1}));
            for j=1:numel(inputs{1})
                if strcmp(blk.Operator, 'sqrt')
                    %code = sprintf('sqrt(%s) ',  inputs{1}{j});
                    code = nasa_toLustre.lustreAst.NodeCallExpr('sqrt', inputs{1}{j});
                elseif strcmp(blk.Operator, 'signedSqrt')
                    %code = sprintf('if %s >= %s then sqrt(%s) else -sqrt(-%s)', inputs{1}{j}, zero, inputs{1}{j}, inputs{1}{j});
                    code = nasa_toLustre.lustreAst.IteExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GTE, inputs{1}{j}, zero),...
                        nasa_toLustre.lustreAst.NodeCallExpr('sqrt', inputs{1}{j}), ...
                        nasa_toLustre.lustreAst.UnaryExpr(UnaryExpr.NEG, ...
                                   nasa_toLustre.lustreAst.NodeCallExpr('sqrt', ...
                                                nasa_toLustre.lustreAst.UnaryExpr(UnaryExpr.NEG,...
                                                        inputs{1}{j}))));
                elseif strcmp(blk.Operator, 'rSqrt')
                    %code = sprintf('%s/sqrt(%s) ', one, inputs{1}{j});
                    code =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, ...
                        one, ...
                        nasa_toLustre.lustreAst.NodeCallExpr('sqrt', inputs{1}{j}));
                end
               
                 if ~strcmp(outLusDT, 'real')
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('real', outputDataType);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format, code);
                    end
                end
                codes{j} = nasa_toLustre.lustreAst.LustreEq( outputs{j}, code);
            end
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                obj.addUnsupported_options(...
                    sprintf('The minimum/maximum value is not support in block %s', HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = true;
        end
       
    end
    
end

