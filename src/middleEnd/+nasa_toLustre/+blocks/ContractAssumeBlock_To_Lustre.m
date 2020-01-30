classdef ContractAssumeBlock_To_Lustre < nasa_toLustre.blocks.SubSystem_To_Lustre
    % ContractAssumeBlock_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin)
            
            write_code@nasa_toLustre.blocks.SubSystem_To_Lustre(obj, ...
                parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin{:});
            [outputs, ~] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk);
            if length(outputs) > 1
                prop = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                    nasa_toLustre.lustreAst.BinaryExpr.AND, outputs);
            elseif length(outputs) == 1
                prop = outputs{1};
            else
                return;
            end
            prop_ID =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            isInsideContract =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
            if LusBackendType.isKIND2(lus_backend) && isInsideContract
                obj.addCode(...
                    nasa_toLustre.lustreAst.ContractAssumeExpr(prop_ID, prop));
            else
                obj.addCode(nasa_toLustre.lustreAst.AssertExpr(prop));
            end
            xml_trace.add_Property(...
                blk.Origin_path, ...
                nasa_toLustre.utils.SLX2LusUtils.node_name_format(parent),...
                prop_ID, 1, 'assume')
        end
        
        function options = getUnsupportedOptions(obj, parent, blk,...
                lus_backend, varargin)
            getUnsupportedOptions@nasa_toLustre.blocks.SubSystem_To_Lustre(obj,...
                parent, blk, lus_backend, varargin{:});
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

