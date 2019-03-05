classdef Bias_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Bias_To_Lustre 
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
            %L = nasa_toLustre.ToLustreImport.L;
            %import(L{:})
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            [inputs] = nasa_toLustre.blocks.Bias_To_Lustre.getBlockInputsNames_convInType2AccType(obj, parent, blk);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};

            [outLusDT] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            if isequal(outLusDT, 'int')
                bias = nasa_toLustre.lustreAst.IntExpr(blk.Bias);
            else
                bias = nasa_toLustre.lustreAst.RealExpr(blk.Bias);
            end
            n = numel(inputs{1});
            codes = cell(1, n);            
            for j=1:n
                %codes{j} = sprintf('%s = %s + %s;', outputs{j}, inputs{1}{j},bias);
                codes{j} = nasa_toLustre.lustreAst.LustreEq(...
                    outputs{j}, ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                                inputs{1}{j}, ...
                                bias));
            end
            obj.setCode(codes);
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            obj.unsupported_options = {...
                sprintf('Block %s is supported by Pre-processing check the pre-processing errors.',...
                HtmlItem.addOpenCmd(blk.Origin_path))};            
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    methods(Static)
        [inputs,widths] = getBlockInputsNames_convInType2AccType(obj, parent, blk)
        
    end
    
end

