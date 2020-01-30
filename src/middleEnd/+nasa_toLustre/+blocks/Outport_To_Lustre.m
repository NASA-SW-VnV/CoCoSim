classdef Outport_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Outport_To_Lustre translates the Outport block
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, coco_backend, varargin)
            global  CoCoSimPreferences;
            [outputs, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            isInsideContract =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
            if isInsideContract && LusBackendType.isKIND2(lus_backend)
                % ignore output "valid" in contract
                return;
            end
            
            if isempty(blk.CompiledPortDataTypes)
                lus_outputDataType = 'real';
            else
                lus_outputDataType =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{1});
            end
            % the case of non connected outport block.
            if isempty(inputs)
                zero =nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
                    0, lus_outputDataType);
                inputs = arrayfun(@(x) {zero}, (1:numel(outputs)));
            end
            %%
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                %codes{i} = sprintf('%s = %s;\n\t', outputs{i}, inputs{i});
                codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{i});
            end
            
            obj.addCode( codes);
            
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lus_outputDataType, xml_trace);
                end
            end
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, ...
                lus_backend, coco_backend, main_sampleTime, varargin)
            
            % Outport in root level should not be of type enumeration in
            % case of Validation backend with Lustrec.
            if CoCoBackendType.isVALIDATION(coco_backend) ...
                    && LusBackendType.isLUSTREC(lus_backend) ...
                    && strcmp(parent.BlockType, 'block_diagram')
                if isempty(blk.CompiledPortDataTypes)
                    hasEnum = false;
                else
                    [~, ~, ~, ~, ~, hasEnum] = ...
                        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{1});
                end
                if hasEnum
                    obj.addUnsupported_options(sprintf('Outport %s with Type %s has/is Enumeration type is not supported in root level for Validation with Lustrec.', ...
                        HtmlItem.addOpenCmd(blk.Origin_path),...
                        blk.CompiledPortDataTypes.Inport{1}));
                end
            end
            
            % Outport at root level should have same sample time of the
            % model
            if strcmp(parent.BlockType, 'block_diagram') ...
                    && isfield(blk, 'CompiledSampleTime')
                inST = blk.CompiledSampleTime;
                if inST(1) ~= 0  &&  ~isinf(inST(1))   && (main_sampleTime(1) ~= inST(1) || main_sampleTime(2) ~= inST(2))
                    obj.addUnsupported_options(sprintf(['Outport %s with Sample time %s in root level is different from model Sample time %s. '...
                        'Outports and Inports at root level should have same sample time of the model. To solve this, you can add Rate transition block just before your Outport and set its Sample time to %s.'], ...
                        HtmlItem.addOpenCmd(blk.Origin_path),...
                        mat2str(blk.CompiledSampleTime), ...
                        mat2str(main_sampleTime), mat2str(main_sampleTime)));
                end
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

