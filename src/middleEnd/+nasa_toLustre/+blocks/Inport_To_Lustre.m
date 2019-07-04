classdef Inport_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %Inport_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            % No need for code for Inport as it is generated in the node
            % header
            
            [outputs, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            outLus_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
            %% add assertions on inputs for intXX types
            try
                isInsideContract =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
                if ismember(outputDataType, {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32'})
                    v_min = nasa_toLustre.lustreAst.IntExpr(double(intmin(outputDataType)));
                    v_max = nasa_toLustre.lustreAst.IntExpr(double(intmax(outputDataType)));
                    nb_outputs = numel(outputs);
                    for j=1:nb_outputs
                        prop = nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                            nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.LTE, v_min, outputs{j}), ...
                            nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.LTE, outputs{j}, v_max));
                        if isInsideContract
                            %obj.addCode(nasa_toLustre.lustreAst.ContractAssumeExpr('', prop));
                        else
                            obj.addCode(nasa_toLustre.lustreAst.AssertExpr(prop));
                        end
                    end
                end
            catch
                %ignore
            end
            %% We add assumptions on the inport values interval if it is
            % mentioned by the user in OutMin/OutMax in Inport dialog box.
            addAsAssertExpr = true;
            DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, outLus_dt, xml_trace, addAsAssertExpr);
            
            
            
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, ...
                lus_backend, coco_backend, main_sampleTime, varargin)
            
            % Outport in first level should not be of type enumeration in
            % case of Validation backend with Lustrec.
            if CoCoBackendType.isVALIDATION(coco_backend) ...
                    && LusBackendType.isLUSTREC(lus_backend) ...
                    && strcmp(parent.BlockType, 'block_diagram')
                if isempty(blk.CompiledPortDataTypes)
                    isEnum = false;
                else
                    [~, ~, ~, ~, isEnum] = ...
                        nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Outport{1});
                end
                if isEnum
                    obj.addUnsupported_options(sprintf('Inport %s with Enumeration Type %s is not supported in root level for Validation with Lustrec.', ...
                        HtmlItem.addOpenCmd(blk.Origin_path),...
                        blk.CompiledPortDataTypes.Outport{1}));
                end
            end
            
            % Inports in root level should have the same model sampleTime
            if strcmp(parent.BlockType, 'block_diagram')
                inST = blk.CompiledSampleTime;
                if main_sampleTime(1) ~= inST(1) || main_sampleTime(2) ~= inST(2)
                    obj.addUnsupported_options(sprintf('Inport %s with Sample time %s is different from Model sample time %s. CoCosim requires Inports at root level to have same sample time as the model.', ...
                        HtmlItem.addOpenCmd(blk.Origin_path),...
                        mat2str(inST), mat2str(main_sampleTime)));
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

