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
function [status, errors_msg] = Memory_pp(model)
% Memory_pp discretizing Memory block by UnitDelay
%   model is a string containing the name of the model to search in
status = 0;
errors_msg = {};

memoryBlk_list = find_system(model, 'LookUnderMasks','all', ...
    'BlockType','Memory');
if not(isempty(memoryBlk_list))
    display_msg('Processing Memory blocks...', MsgType.INFO, 'Memory_pp', '');
    validDT = {'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
        'int32', 'uint32', 'boolean'};
    allCompiledDT = SLXUtils.getCompiledParam(memoryBlk_list, 'CompiledPortDataTypes');
    for i=1:length(memoryBlk_list)
        display_msg(memoryBlk_list{i}, MsgType.INFO, 'Memory_pp', '');
        try
            % get block informations
            try
                InitialCondition = get_param(memoryBlk_list{i},'InitialCondition' );
            catch
                %InitialCondition does not exist in R2015b
                InitialCondition = get_param(memoryBlk_list{i},'X0' );
            end
            %Statename does not exist in R2015b
            %StateName = get_param(memoryBlk_list{i}, 'StateName');
            StateMustResolveToSignalObject = get_param(memoryBlk_list{i}, 'StateMustResolveToSignalObject');
            StateSignalObject = get_param(memoryBlk_list{i},'StateSignalObject');
            StateStorageClass = get_param(memoryBlk_list{i}, 'StateStorageClass');
            % replace it
            NASAPPUtils.replace_one_block(memoryBlk_list{i},'pp_lib/Memory');
            unitDelayPath = fullfile(memoryBlk_list{i}, 'U');
            %restore information
            set_param(unitDelayPath ,'InitialCondition', InitialCondition);
            %Statename does not exist in R2015b
            %set_param(memoryBlk_list{i} ,'StateName', StateName);
            set_param(unitDelayPath ,'StateMustResolveToSignalObject', StateMustResolveToSignalObject);
            set_param(unitDelayPath ,'StateSignalObject', StateSignalObject);
            set_param(unitDelayPath ,'StateStorageClass', StateStorageClass);
            
            % set Datatype
            CompiledPortDataTypes = allCompiledDT{i};
            if ismember(CompiledPortDataTypes.Inport{1}, validDT)
                % Make sure they give same datatype
                set_param(fullfile(memoryBlk_list{i}, 'S'),...
                    'OutDataTypeStr', CompiledPortDataTypes.Inport{1});
            end
            % expand it to make unit delay clear.
            ExpandNonAtomicSubsystems_pp(memoryBlk_list{i});
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('memoryBlk pre-process has failed for block %s', memoryBlk_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'Memory_pp', '');
end
end

