classdef Abs_To_Lustre < Block_To_Lustre
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
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                display_msg(sprintf('The minimum/maximum value is not supported in block %s',...
                    blk.Origin_path), MsgType.WARNING, 'Abs_To_Lustre', '');
            end
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport(1);
            %converts the input data type(s) to
            %its accumulator data type
            if ~strcmp(inport_dt, outputDataType)
                RndMeth = blk.RndMeth;
                SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
                [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(external_lib)
                    obj.addExternal_libraries(external_lib);
                    inputs{1} = cellfun(@(x) ...
                        SLX2LusUtils.setArgInConvFormat(conv_format,x), inputs{1}, 'un', 0);
                end
            end
            
            [~, zero] = SLX2LusUtils.get_lustre_dt(outputDataType);
            
            codes = {};
            for j=1:numel(inputs{1})
                code = IteExpr(...
                    BinaryExpr(BinaryExpr.GTE, inputs{1}{j}, zero),...
                    inputs{1}{j}, ...
                    UnaryExpr(UnaryExpr.NEG, inputs{1}{j}));
                codes{j} = LustreEq(outputs{j}, code);
            end
            
            obj.setCode(codes);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                obj.addUnsupported_options(...
                    sprintf('The minimum/maximum value is not supported in block %s', blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
    end
    
end

