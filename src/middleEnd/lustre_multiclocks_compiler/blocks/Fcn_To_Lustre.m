classdef Fcn_To_Lustre < Block_To_Lustre
    %Fcn_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        isBooleanExpr = 0;
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            
            inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
            inport_dt = blk.CompiledPortDataTypes.Inport(1);
            %converts the input data type(s) to
            %its output data type
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
            
            obj.isBooleanExpr = 0;
            [lusCode, status] = ...
                Exp2Lus.expToLustre(obj, blk.Expr, parent, blk, inputs);
            if status
                display_msg(sprintf('ParseError  character unsupported  %s in block %s', ...
                    unsupportedExp, blk.Origin_path), ...
                    MsgType.ERROR, 'Exp2Lus.expToLustre', '');
                return;
            end
            if obj.isBooleanExpr
                lusCode = IteExpr(lusCode, RealExpr('1.0'),  RealExpr('0.0'));
            end
            obj.setCode(LustreEq(outputs{1}, lusCode));
            obj.addVariable(outputs_dt);
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            [tree, status, unsupportedExp] = Fcn_Exp_Parser.parse(blk.Expr);
            if status
                obj.addUnsupported_options(sprintf('ParseError  character unsupported  %s in block %s', ...
                    unsupportedExp, blk.Origin_path));
            end
            obj.isBooleanExpr = 0;
            try
                inputs{1} = SLX2LusUtils.getBlockInputsNames(parent, blk, 1);
                Fcn_To_Lustre.tree2code(obj, tree, parent, blk, inputs, 'real');
            catch me
                if strcmp(me.identifier, 'COCOSIM:TREE2CODE')
                    obj.addUnsupported_options(me.message);
                end
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(obj, varargin)
            is_Abstracted = ~isempty(obj.getExternalLibraries);
        end
    end
    
end

