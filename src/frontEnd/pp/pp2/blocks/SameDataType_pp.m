function SameDataType_pp( new_model_base )
%sameDT_process requires all inputs and outputs to have the same data type.
%Blocks: Logical operators
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ssys_list = find_system(new_model_base,'LookUnderMasks','all', 'BlockType','Logic');
if not(isempty(ssys_list))
    display_msg('Processing Logical Operators to ensure inputs have the same DatType'...
        , MsgType.INFO, 'PP', '');
    for i=1:length(ssys_list)
        set_param(ssys_list{i},'AllPortsSameDT','on');
    end
end



ssys_list = ...
    find_system(new_model_base,'LookUnderMasks','all', 'BlockType','RelationalOperator');
ssys_list = [ssys_list; ...
    find_system(new_model_base,'LookUnderMasks','all', 'BlockType','Lookup_n-D')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'LookUnderMasks','all', 'BlockType','Sum')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'LookUnderMasks','all', 'BlockType','Product')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'LookUnderMasks','all', 'BlockType','DotProduct')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'LookUnderMasks','all', 'BlockType','MinMax')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'LookUnderMasks','all', 'BlockType','MultiPortSwitch')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'LookUnderMasks','all', 'BlockType','Switch')];



if not(isempty(ssys_list))
    display_msg('Processing Logical Operators to ensure inputs have the same DatType'...
        , MsgType.INFO, 'PP', '');
    for i=1:length(ssys_list)
        set_param(ssys_list{i},'InputSameDT','on');
    end
end



end

