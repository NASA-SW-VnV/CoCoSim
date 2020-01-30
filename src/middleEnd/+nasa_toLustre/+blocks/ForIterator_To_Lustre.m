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
classdef ForIterator_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %ForIterator_To_Lustre is partially supported by SubSystem_To_Lustre.
    %Here we add only not supported options

    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            % join the lines and set the block code.
            obj.addCode( nasa_toLustre.lustreAst.LustreEq(outputs{1},nasa_toLustre.utils.SLX2LusUtils.iterationVariable()));
        end
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            if strcmp(blk.IterationSource, 'external')
                obj.addUnsupported_options(...
                    sprintf('Block "%s" has external iteration limit source. Only internal option is supported', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            if strcmp(blk.ExternalIncrement, 'on')
                obj.addUnsupported_options(...
                    sprintf('Block "%s" has external increment which is not supported.', ...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            [~, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IterationLimit);
            if status
                obj.addUnsupported_options(...
                    sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.IterationLimit, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            %
            Actionblks = nasa_toLustre.frontEnd.Block_To_Lustre.find_blocks(parent, 'BlockType', 'ActionPort');
            Enableblks = nasa_toLustre.frontEnd.Block_To_Lustre.find_blocks(parent, 'BlockType', 'EnablePort');
            Actionblks = [Actionblks, Enableblks];
            if ~isempty(Actionblks)
                for i=1:numel(Actionblks)
                    if isfield(Actionblks{i}, 'InitializeStates') ...
                            && strcmp(Actionblks{i}.InitializeStates, 'held')
                        obj.addUnsupported_options(...
                            sprintf('Bock "%s" has option "held" inside ForIterator Subsystem "%s". Only "reset" option is supported if the ActionPort block is inside a For Iterator Subsystem.',...
                            Actionblks{i}.Origin_path, parent.Origin_path));
                    elseif isfield(Actionblks{i}, 'StatesWhenEnabling') ...
                            && strcmp(Actionblks{i}.StatesWhenEnabling, 'held')
                        obj.addUnsupported_options(...
                            sprintf('Bock "%s" has option "held" inside ForIterator Subsystem "%s". Only "reset" option is supported if the Enable Port block is inside a For Iterator Subsystem.',...
                            Actionblks{i}.Origin_path, parent.Origin_path));
                    else
                        try
                            action_parant = get_struct(parent, ...
                                regexprep(fileparts(Actionblks{i}.Origin_path), ...
                                fullfile(parent.Origin_path, '/'), ''));
                        catch me
                            continue;
                        end
                        ActionSS_Outports = nasa_toLustre.frontEnd.Block_To_Lustre.find_blocks(action_parant, 'BlockType', 'Outport');
                        for j=1:numel(ActionSS_Outports)
                            if isfield(ActionSS_Outports{j}, 'OutputWhenDisabled') ...
                                    && strcmp(ActionSS_Outports{j}.OutputWhenDisabled, 'held')
                                obj.addUnsupported_options(...
                                    sprintf('Bock "%s" has option "held" inside ForIterator Subsystem "%s". Only "reset" option is supported if the Outport block is inside a For Iterator Subsystem.',...
                                    ActionSS_Outports{j}.Origin_path, parent.Origin_path));
                            end
                        end
                    end
                end
            end
            %Blocks with memories
            all_blks = nasa_toLustre.frontEnd.Block_To_Lustre.find_blocks(parent);
            for i=1:numel(all_blks)
                if isfield(all_blks{i}, 'StateName')
                    blk_parent = fileparts(all_blks{i}.Origin_path);
                    if ~strcmp(parent.Origin_path, blk_parent)
                        obj.addUnsupported_options(...
                            sprintf('Bock "%s" is a memory block inside ForIterator Subsystem "%s". Memory blocks are only allowed in the first level of the For Iterator Subsystem.',...
                            all_blks{i}.Origin_path, parent.Origin_path));
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

