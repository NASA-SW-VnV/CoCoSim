classdef Logic_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Logic_To_Lustre
    % supporting: AND, OR, NAND, NOR, XOR, NXOR, NOT
    
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
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            out_lus_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            if ~strcmp(out_lus_dt, 'bool')
                [external_lib, out_conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('bool', outputDataType);
                if ~isempty(external_lib)
                    obj.addExternal_libraries(external_lib);
                end
            else
                out_conv_format = {};
            end
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                lus_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(inport_dt);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(lus_dt, 'bool')
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'bool');
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                rhs = {};
                if nbInputs==1
                    scalars = cell(1, numel(inputs{1}));
                    for j=1:numel(inputs{1})
                        scalars{j} = inputs{1}{j};
                    end
                else
                    scalars = cell(1, nbInputs);
                    for j=1:nbInputs
                        scalars{j} = inputs{j}{i};
                    end
                end
                if strcmp(blk.Operator, 'AND')
                    rhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, scalars);
                elseif strcmp(blk.Operator, 'OR')
                    rhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.OR, scalars);
                elseif strcmp(blk.Operator, 'XOR')
                    rhs = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.XOR, scalars);
                elseif strcmp(blk.Operator, 'NOT')
                    rhs = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, inputs{1}{i});
                elseif strcmp(blk.Operator, 'NAND')
                    rhs = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, ...
                        nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.AND, scalars));
                elseif strcmp(blk.Operator, 'NOR')
                    rhs = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, ...
                        nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.OR, scalars));
                elseif strcmp(blk.Operator, 'NXOR')
                    rhs = nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, ...
                        nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.XOR, scalars));
                end
                if ~isempty(out_conv_format)
                    rhs =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(out_conv_format,rhs);
                end
                codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, rhs);
            end
            obj.setCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        
        %%
        function options = getUnsupportedOptions(obj, varargin)
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

