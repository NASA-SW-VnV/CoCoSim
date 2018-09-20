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
            inport_dt = blk.CompiledPortDataTypes.Inport{1};
            %converts the input data type(s) to
            %its accumulator data type
            if ~strcmp(inport_dt, outputDataType)
                RndMeth = blk.RndMeth;
                SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
                [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                if ~isempty(external_lib)
                    obj.addExternal_libraries(external_lib);
                end
            else
                conv_format = {};
            end
            
            [~, zero] = SLX2LusUtils.get_lustre_dt(outputDataType);
            
            
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
                    conds{1} = BinaryExpr(BinaryExpr.EQ, ...
                        inputs{1}{j}, ...
                        IntExpr(v_min));
                    thens{1} = IntExpr(v_min);
                end
                conds{n} = BinaryExpr(BinaryExpr.GTE, ...
                    inputs{1}{j}, zero);
                thens{n} = inputs{1}{j};
                thens{n+1} = UnaryExpr(UnaryExpr.NEG, ...
                    inputs{1}{j});
                code = ...
                    SLX2LusUtils.setArgInConvFormat(...
                    conv_format,...
                    IteExpr.nestedIteExpr(conds, thens));
                codes{j} = LustreEq(outputs{j}, code);
            end
            
            obj.setCode(codes);
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            obj.unsupported_options = {};
            if ~strcmp(blk.OutMax, '[]') || ~strcmp(blk.OutMin, '[]')
                obj.addUnsupported_options(...
                    sprintf('The minimum/maximum value is not supported in block %s', blk.Origin_path));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

