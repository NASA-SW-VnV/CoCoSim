classdef Switch_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Switch_To_Lustre
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
            
            
            if strcmp(blk.AllowDiffInputSizes, 'on')
                display_msg(sprintf('The Allow different data input sizes option is not support in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'Switch_To_Lustre', '');
            end
            
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            [threshold, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Threshold);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Threshold, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustre', '');
                return;
            end
            secondInputIsBoolean = 0;
            threshold_ast = {};
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType) && i~=2
                    [external_lib, conv_format] = ...
                       nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x), ...
                            inputs{i}, 'un', 0);
                    end
                elseif i==2
                    [lus_inportDataType, ~] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
                    if strcmp(blk.Criteria, 'u2 ~= 0')
                        if strcmp(lus_inportDataType, 'real')
                            threshold_str_temp = RealExpr('0.0');
                        elseif strcmp(lus_inportDataType, 'int')
                            threshold_str_temp = IntExpr(0);
                        else
                            threshold_str_temp = BooleanExpr('false');
                            secondInputIsBoolean = 1;
                        end
                        threshold_ast = cell(1, max_width);
                        for j=1:max_width
                            threshold_ast{j} = threshold_str_temp;
                        end
                            
                    else
                        threshold_ast = cell(1, numel(threshold));
                        for j=1:numel(threshold)
                            if strcmp(lus_inportDataType, 'real')
                                threshold_ast{j} = RealExpr(threshold(j));
                            elseif strcmp(lus_inportDataType, 'int')
                                threshold_ast{j} = IntExpr(int32(threshold(j)));
                            else
                                secondInputIsBoolean = 1;
                            end
                        end
                        if numel(threshold) < max_width && ~secondInputIsBoolean
                            threshold_ast = arrayfun(@(x) threshold_ast{1},...
                                (1:max_width), 'UniformOutput', 0);
                        end
                        if numel(inputs{i}) < max_width
                            inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                        end                        %
                    end
                end
            end
            
            
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                if secondInputIsBoolean
                    cond = inputs{2}{i};
                else
                    if strcmp(blk.Criteria, 'u2 > Threshold')
                        cond = BinaryExpr(BinaryExpr.GT, ...
                            inputs{2}{i}, threshold_ast{i});
                    elseif strcmp(blk.Criteria, 'u2 >= Threshold')
                        cond = BinaryExpr(BinaryExpr.GTE, ...
                            inputs{2}{i}, threshold_ast{i});
                    elseif strcmp(blk.Criteria, 'u2 ~= 0')
                        cond = BinaryExpr(BinaryExpr.NEQ, ...
                            inputs{2}{i}, threshold_ast{i});
                    end
                end
                codes{i} = LustreEq(outputs{i}, ...
                    IteExpr(cond, inputs{1}{i}, inputs{3}{i}));
            end
            
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        %%
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                obj.addUnsupported_options(...
                    sprintf('The minimum/maximum value is not support in block %s', HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            if strcmp(blk.AllowDiffInputSizes, 'on')
                obj.addUnsupported_options(...
                    sprintf('The Allow different data input sizes option is not support in block %s', HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

