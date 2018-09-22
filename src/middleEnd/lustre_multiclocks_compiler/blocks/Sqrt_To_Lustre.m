classdef Sqrt_To_Lustre < Block_To_Lustre
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
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                display_msg(sprintf('The minimum/maximum value is not support in block %s',...
                    blk.Origin_path), MsgType.WARNING, 'Sqrt_To_Lustre', '');
            end
            if strcmp(blk.AlgorithmType, 'Newton-Raphson')
                msg = sprintf('Option Newton-Raphson is not supported in block %s. Exact method will be used.', ...
                    blk.Origin_path);
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
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, 'double')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'double', RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            [outLusDT, zero, one] = SLX2LusUtils.get_lustre_dt(outputDataType);
            
            codes = cell(1, numel(inputs{1}));
            for j=1:numel(inputs{1})
                if strcmp(blk.Operator, 'sqrt')
                    %code = sprintf('sqrt(%s) ',  inputs{1}{j});
                    code = NodeCallExpr('sqrt', inputs{1}{j});
                elseif strcmp(blk.Operator, 'signedSqrt')
                    %code = sprintf('if %s >= %s then sqrt(%s) else -sqrt(-%s)', inputs{1}{j}, zero, inputs{1}{j}, inputs{1}{j});
                    code = IteExpr(...
                        BinaryExpr(BinaryExpr.GTE, inputs{1}{j}, zero),...
                        NodeCallExpr('sqrt', inputs{1}{j}), ...
                        UnaryExpr(UnaryExpr.NEG, ...
                                   NodeCallExpr('sqrt', ...
                                                UnaryExpr(UnaryExpr.NEG,...
                                                        inputs{1}{j}))));
                elseif strcmp(blk.Operator, 'rSqrt')
                    %code = sprintf('%s/sqrt(%s) ', one, inputs{1}{j});
                    code =  BinaryExpr(BinaryExpr.DIVIDE, ...
                        one, ...
                        NodeCallExpr('sqrt', inputs{1}{j}));
                end
               
                 if ~strcmp(outLusDT, 'real')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion('real', outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        code = SLX2LusUtils.setArgInConvFormat(conv_format, code);
                    end
                end
                codes{j} = LustreEq( outputs{j}, code);
            end
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                obj.addUnsupported_options(...
                    sprintf('The minimum/maximum value is not support in block %s', blk.Origin_path));
            end
            options = obj.getUnsupportedOptions();
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = true;
        end
       
    end
    
end

