function [status, errors_msg] = Memory_pp(model)
% Memory_pp discretizing Memory block by UnitDelay
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
            PP2Utils.replace_one_block(memoryBlk_list{i},'pp_lib/Memory');
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
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('memoryBlk pre-process has failed for block %s', memoryBlk_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'Memory_pp', '');
end
end

