function [all_blks_type] = get_BlocksType(folder)
%GET_BLOCKSTYPE Summary of this function goes here
%   Detailed explanation goes here
slx_files = dir(fullfile(folder, '*.slx'));
mdl_files = dir(fullfile(folder, '*.mdl'));
all_files = [slx_files, mdl_files];
all_blks_type = [];
for i=1:numel(all_files)
    [~, base_name, ~] = fileparts( all_files(i).name);
    try
    load_system(fullfile(folder, ...
        all_files(i).name));
    list_of_all_blacks = find_system(base_name);
    blks_types = get_param(list_of_all_blacks(2:end), 'BlockType');
    all_blks_type= [ all_blks_type; blks_types];
    close_system(base_name, 0);
    catch
        fprintf('couldnt load model %s',base_name );
    end
end
all_blks_type = unique(all_blks_type);
save   all_blks_type all_blks_type

end

