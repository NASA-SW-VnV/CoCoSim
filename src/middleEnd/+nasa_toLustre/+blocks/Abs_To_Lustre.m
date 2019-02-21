classdef Abs_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Abs_To_Lustre
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
            [outputs, outputs_dt] = nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            inputs{1} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport{1};
            %converts the input data type(s) to
            %its accumulator data type
            if ~strcmp(inport_dt, outputDataType)
                RndMeth = blk.RndMeth;
                SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
                [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                end
            else
                conv_format = {};
            end
            
            [~, zero] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            
            
            if MatlabUtils.startsWith(inport_dt, 'int')
                n = 2;
            else
                n =1;
            end
            codes = cell(1, numel(inputs{1}));
            for j=1:numel(inputs{1})
                % if the inport type is int8, int16 ... the absolute value of
                % -128 for int8 is -128.
                conds = cell(1, n);
                thens = cell(1, n+1);
                if MatlabUtils.startsWith(inport_dt, 'int')
                    v_min = double(intmin(inport_dt));
                    conds{1} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, ...
                        inputs{1}{j}, ...
                         nasa_toLustre.lustreAst.IntExpr(v_min));
                    thens{1} = nasa_toLustre.lustreAst.IntExpr(v_min);
                end
                conds{n} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GTE, ...
                    inputs{1}{j}, zero);
                thens{n} = inputs{1}{j};
                thens{n+1} = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, ...
                    inputs{1}{j});
                code = ...
                   nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                    conv_format,...
                    nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
                codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, code);
            end
            
            obj.setCode(codes);
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                obj.addUnsupported_options(...
                    sprintf('The minimum/maximum value is not supported in block %s', HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

