classdef MultiPortSwitch_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %FromWorkspace_To_Lustre 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            [inputs] = getBlockInputsNames_convInType2AccType(obj, parent, blk);
            
            [numInputs, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Inputs);
            blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            
            portIndex = nasa_toLustre.lustreAst.VarIdExpr(sprintf('%s_portIndex',blk_name));
            obj.addVariable(nasa_toLustre.lustreAst.LustreVar(portIndex, 'int'));
            
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
            codes{1} = nasa_toLustre.lustreAst.LustreEq(portIndex, ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                            inputs{1}{1},...
                            nasa_toLustre.lustreAst.IntExpr(indexShift)));
            %sprintf('%s = %s + %d; \n\t', portIndex, inputs{1}{1},indexShift);
                        
            for i=1:numel(outputs)
                %code = sprintf('%s = \n\t', outputs{i});
                conds = cell(1, numInputs);
                thens = cell(1, numInputs + 1);
                for j=1:numInputs
                    conds{j} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, portIndex, nasa_toLustre.lustreAst.IntExpr(j));
                    thens{j} = inputs{j+1}{i};
                    %code = sprintf('%s  if(%s = %d) then %s\n\t', code, portIndex,j,inputs{j+1}{i});   % 1st port is control port
                end
                thens{numInputs + 1} = inputs{numel(inputs)}{i};
                %codes{i + 1} = sprintf('%s  else %s ;\n\t', code,inputs{numel(inputs)}{i});   % default port is always last port whether there is additional port or not
                codes{i + 1} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                    nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
            end
            
            obj.addCode( codes );
            
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    outputDataType = blk.CompiledPortDataTypes.Outport{1};
                    lusOutDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
            
        end
        
        [inputs] = getBlockInputsNames_convInType2AccType(obj, parent, blk)        
        
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

