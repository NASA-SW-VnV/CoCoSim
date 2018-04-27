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
        
        function  write_code(obj, parent, blk, varargin)
            
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            inputs = {};
            
            widths = blk.CompiledPortWidths.Inport;
            nbInputs = numel(widths);
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
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
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, outputDataType);
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                elseif i==1 && ~strcmp(inLusDT, 'int')
                    [external_lib, conv_format] = SLX2LusUtils.dataType_conversion(inport_dt, 'int');
                    if ~isempty(external_lib)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) sprintf(conv_format,x), inputs{i}, 'un', 0);
                    end
                end
            end

            [outLusDT, ~, one] = SLX2LusUtils.get_lustre_dt(outputDataType);
            
            [numInputs, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Inputs);
            blk_name = SLX2LusUtils.node_name_format(blk);
            
            addVarIndex = 0;
            addVarIndex = addVarIndex + 1;
            portIndex = sprintf('%s_portIndex',blk_name);
            addVars{addVarIndex} = sprintf('%s:int;',portIndex);
            codes = {}; 
            codeIndex = 0;
            indexShift = 0;    % portIndex = readin index + indexShift.  
            %                    indexShift = 0 for 1-based contiguous (1st port is control port)
            %                    indexShift = 2 for 0-based contigous        
               
            if strcmp(blk.DataPortOrder, 'Zero-based contiguous')
                indexShift = indexShift + 1;
            elseif strcmp(blk.DataPortOrder, 'Specify indices')
                display_msg(sprintf('Specify indices is not supported  in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'MultiportSwitch_To_Lustre', '');
            end
            
            codeIndex = codeIndex + 1;
            codes{codeIndex} = sprintf('%s = %s + %d; \n\t', portIndex, inputs{1}{1},indexShift);
                        
            for i=1:numel(outputs)
                code = sprintf('%s = \n\t', outputs{i});
                for j=1:numInputs
                    if j==1
                        code = sprintf('%s  if(%s = %d) then %s\n\t', code, portIndex,j,inputs{j+1}{i});   % 1st port is control port
                    else
                        code = sprintf('%s else if(%s = %d) then %s\n\t', code, portIndex,j,inputs{j+1}{i});
                    end
                end
                codeIndex = codeIndex + 1;
                codes{codeIndex} = sprintf('%s  else %s ;\n\t', code,inputs{numel(inputs)}{i});   % default port is always last port whether there is additional port or not
            end
            
            obj.setCode(MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
            obj.addVariable(addVars);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {};
            if strcmp(blk.DataPortOrder, 'Specify indices')
                obj.addUnsupported_options(...
                    sprintf('Specify indices is not supported  in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'MultiportSwitch_To_Lustre', '');
            end    
            if strcmp(blk.AllowDiffInputSizes, 'on')
                obj.addUnsupported_options(...
                    sprintf('Allow different data input sizes is not supported  in block %s',...
                    blk.Origin_path), MsgType.ERROR, 'MultiportSwitch_To_Lustre', '');
            end             
            options = obj.unsupported_options;
        end
    end
    
end

