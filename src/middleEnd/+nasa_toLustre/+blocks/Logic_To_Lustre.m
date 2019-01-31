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
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            
            
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            out_lus_dt = SLX2LusUtils.get_lustre_dt(outputDataType);
            if ~strcmp(out_lus_dt, 'bool')
                [external_lib, out_conv_format] = SLX2LusUtils.dataType_conversion('bool', outputDataType);
                if ~isempty(external_lib)
                    obj.addExternal_libraries(external_lib);
                end
            else
                out_conv_format = {};
            end
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                lus_dt = SLX2LusUtils.get_lustre_dt(inport_dt);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(lus_dt, 'bool')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'bool');
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
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
                    rhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, scalars);
                elseif strcmp(blk.Operator, 'OR')
                    rhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, scalars);
                elseif strcmp(blk.Operator, 'XOR')
                    rhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.XOR, scalars);
                elseif strcmp(blk.Operator, 'NOT')
                    rhs = UnaryExpr(UnaryExpr.NOT, inputs{1}{i});
                elseif strcmp(blk.Operator, 'NAND')
                    rhs = UnaryExpr(UnaryExpr.NOT, ...
                        BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, scalars));
                elseif strcmp(blk.Operator, 'NOR')
                    rhs = UnaryExpr(UnaryExpr.NOT, ...
                        BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, scalars));
                elseif strcmp(blk.Operator, 'NXOR')
                    rhs = UnaryExpr(UnaryExpr.NOT, ...
                        BinaryExpr.BinaryMultiArgs(BinaryExpr.XOR, scalars));
                end
                if ~isempty(out_conv_format)
                    rhs = SLX2LusUtils.setArgInConvFormat(out_conv_format,rhs);
                end
                codes{i} = LustreEq(outputs{i}, rhs);
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

