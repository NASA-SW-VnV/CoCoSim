function sameDT_process( new_model_base )
%sameDT_process requires all inputs and outputs to have the same data type.
%Blocks: Logical operators

ssys_list = find_system(new_model_base,'BlockType','Logic');
if not(isempty(ssys_list))
    display_msg('Processing Logical Operators to ensure inputs have the same DatType'...
        , MsgType.INFO, 'PP', '');
    for i=1:length(ssys_list)
        set_param(ssys_list{i},'AllPortsSameDT','on');
    end
end



ssys_list = ...
    find_system(new_model_base,'BlockType','RelationalOperator');
ssys_list = [ssys_list; ...
    find_system(new_model_base,'BlockType','Lookup_n-D')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'BlockType','Sum')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'BlockType','Product')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'BlockType','DotProduct')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'BlockType','MinMax')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'BlockType','MultiPortSwitch')];
ssys_list = [ssys_list; ...
    find_system(new_model_base,'BlockType','Switch')];



if not(isempty(ssys_list))
    display_msg('Processing Logical Operators to ensure inputs have the same DatType'...
        , MsgType.INFO, 'PP', '');
    for i=1:length(ssys_list)
        set_param(ssys_list{i},'InputSameDT','on');
    end
end



end

