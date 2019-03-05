classdef Polyval_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Polyval_To_Lustre
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
            %L = nasa_toLustre.ToLustreImport.L;
            %import(L{:})
            
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            out_lus_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            obj.addVariable(outputs_dt);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            slx_inport_dt = blk.CompiledPortDataTypes.Inport(1);
            [lus_inport_dt] = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_inport_dt);
            if ~strcmp(lus_inport_dt, 'real')
                % transfor first to bool
                [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(slx_inport_dt, 'real');
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                    inputs = cellfun(@(x) ...
                        nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                        inputs, 'un', 0);
                end
            end
            
            [coefs, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent,...
                blk, blk.Coefs);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.coefs, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustre', '');
                return;
            end
            
            if ~strcmp(out_lus_dt, 'real')
                % transfor first to bool
                [external_lib, out_conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(out_lus_dt, 'real');
                if ~isempty(out_conv_format)
                    obj.addExternal_libraries(external_lib);
                end
            else
                out_conv_format = [];
            end
            obj.addExternal_libraries('LustMathLib_lustrec_math');
            %y = p_1*x^n + p_2*x^(n?1) + ? + p_n*x + p_(n+1)
            polynom_degree = length(coefs) - 1;
            pows = (polynom_degree:-1:1);
            for outIdx=1:length(outputs)
                x_power = arrayfun(@(x) ...
                    nasa_toLustre.lustreAst.NodeCallExpr('pow', {inputs{outIdx}, nasa_toLustre.lustreAst.RealExpr(x)}), ...
                    pows, 'un', 0);
                product_terms = arrayfun(@(i) ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY, x_power{i},  nasa_toLustre.lustreAst.RealExpr(coefs(i))), ...
                    (1:polynom_degree), 'un', 0);
                product_terms{end+1} = nasa_toLustre.lustreAst.RealExpr(coefs(end));
                rhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS, product_terms);
                if ~isempty(out_conv_format)
                    rhs = nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(out_conv_format,rhs);
                end
                obj.addCode(nasa_toLustre.lustreAst.LustreEq(outputs{outIdx}, rhs));
            end
            
            
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

