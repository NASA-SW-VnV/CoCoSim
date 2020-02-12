%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef ContractBlock_To_Lustre < nasa_toLustre.blocks.SubSystem_To_Lustre
    % ContractBlock_To_Lustre translates contract observer as contract in
    % kind2

    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin)
            if coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
                % Contracts Subsystems willl be ignored as they will be
                % imported in the node definition of the associate Simulink
                % Subsystem. See SS_To_LustreNode.subsystem2node function
                return;
            end
            write_code@nasa_toLustre.blocks.SubSystem_To_Lustre(obj, ...
                parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin{:});
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, lus_backend, varargin)
            % add your unsuported options list here
            associatedBlkHandle = blk.AssociatedBlkHandle;
            associatedBlk = get_struct(parent, associatedBlkHandle);
            if ~(isempty(associatedBlk.CompiledPortWidths.Enable) ...
                    && isempty(associatedBlk.CompiledPortWidths.Ifaction)...
                    && isempty(associatedBlk.CompiledPortWidths.Reset)...
                    && isempty(associatedBlk.CompiledPortWidths.Trigger))
                format = 'Contract "%s" can not be associated with "%s" which is Conditionally Executed Subsystem.\n';
                format = [format, ...
                    'Please Create a Subsystem from the block and linked it again to the contract.'];
                obj.addUnsupported_options(...
                    sprintf(format, HtmlItem.addOpenCmd(blk.Origin_path), HtmlItem.addOpenCmd(associatedBlk.Origin_path)));
            end
            %Kind2 does not support node calls in contract with more than one output.
            % We should look for any block with multidimensional output or many
            % outputs.
            if isfield(blk, 'Content')
                field_names = fieldnames(blk.Content);
                field_names = ...
                    field_names(...
                    cellfun(@(x) isfield(blk.Content.(x),'BlockType'), field_names));
                for i=1:numel(field_names)
                    child = blk.Content.(field_names{i});
                    if strcmp(child.BlockType, 'Inport')
                        continue;
                    end
                    [outputs, ~] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(blk, child);
                    if numel(outputs) > 1
                        obj.addUnsupported_options(...
                            sprintf('Block %s has more than one outputs. All Subsystems inside Contract should have one output. You can move this block inside a Guarantee/Assume block. For Guarantee/Assume blocks the output should be one scalar boolean.', ...
                            HtmlItem.addOpenCmd(child.Origin_path)))
                    end
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

