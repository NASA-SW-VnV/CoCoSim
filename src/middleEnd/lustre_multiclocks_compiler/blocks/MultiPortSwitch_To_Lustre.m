classdef MultiPortSwitch_To_Lustre < Block_To_Lustre
    %FromWorkspace_To_Lustre 
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
            obj.addVariable(outputs_dt);
            [inputs] = getBlockInputsNames_convInType2AccType(obj, parent, blk);
            
            [numInputs, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Inputs);
            blk_name = SLX2LusUtils.node_name_format(blk);
            
            portIndex = VarIdExpr(sprintf('%s_portIndex',blk_name));
            obj.addVariable(LustreVar(portIndex, 'int'));
            
            indexShift = 0;    % portIndex = readin index + indexShift.  
            %                    indexShift = 0 for 1-based contiguous (1st port is control port)
            %                    indexShift = 2 for 0-based contigous        
               
            if strcmp(blk.DataPortOrder, 'Zero-based contiguous')
                indexShift = indexShift + 1;
            elseif strcmp(blk.DataPortOrder, 'Specify indices')
                display_msg(sprintf('Specify indices is not supported  in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'MultiportSwitch_To_Lustre', '');
            end
            
            codes = cell(1, numel(outputs) + 1); 
            codes{1} = LustreEq(portIndex, ...
                BinaryExpr(BinaryExpr.PLUS, ...
                            inputs{1}{1},...
                            IntExpr(indexShift)));
            %sprintf('%s = %s + %d; \n\t', portIndex, inputs{1}{1},indexShift);
                        
            for i=1:numel(outputs)
                %code = sprintf('%s = \n\t', outputs{i});
                conds = cell(1, numInputs);
                thens = cell(1, numInputs + 1);
                for j=1:numInputs
                    conds{j} = BinaryExpr(BinaryExpr.EQ, portIndex, IntExpr(j));
                    thens{j} = inputs{j+1}{i};
                    %code = sprintf('%s  if(%s = %d) then %s\n\t', code, portIndex,j,inputs{j+1}{i});   % 1st port is control port
                end
                thens{numInputs + 1} = inputs{numel(inputs)}{i};
                %codes{i + 1} = sprintf('%s  else %s ;\n\t', code,inputs{numel(inputs)}{i});   % default port is always last port whether there is additional port or not
                codes{i + 1} = LustreEq(outputs{i}, ...
                    IteExpr.nestedIteExpr(conds, thens));
            end
            
            obj.setCode( codes );
            
            
        end
        
        function [inputs] = getBlockInputsNames_convInType2AccType(obj, parent, blk)            
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            RndMeth = blk.RndMeth;
            SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
            inputs = cell(1, nbInputs);
            for i=1:nbInputs
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                [inLusDT] = SLX2LusUtils.get_lustre_dt(inport_dt);
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, outputDataType) && i~=1
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType, RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                elseif i==1 && ~strcmp(inLusDT, 'int')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'int');
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x)...
                            SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
        end
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            if strcmp(blk.DataPortOrder, 'Specify indices')
                obj.addUnsupported_options(...
                    sprintf('Specify indices is not supported  in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end    
            if strcmp(blk.AllowDiffInputSizes, 'on')
                obj.addUnsupported_options(...
                    sprintf('Allow different data input sizes is not supported  in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end             
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

