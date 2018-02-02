function [report] = get_BlocksType(folder)
%GET_BLOCKSTYPE Summary of this function goes here
%   Detailed explanation goes here
slx_files = dir(fullfile(folder, '*.slx'));
mdl_files = dir(fullfile(folder, '*.mdl'));
all_files = [slx_files, mdl_files];
report = {};

for i=1:numel(all_files)
    [~, base_name, ~] = fileparts( all_files(i).name);
    try
        load_system(fullfile(folder, ...
            all_files(i).name));
        list_of_all_blacks = find_system(base_name);
        for j=2:numel(list_of_all_blacks)
            block_path = list_of_all_blacks{j};
            blks_type = get_param(block_path, 'BlockType');
            
            dialog_param = get_param(block_path, 'DialogParameters');
            S = struct();
            S.BlkType = blks_type;
            if ~isempty(dialog_param)
                fields = fieldnames(dialog_param);
                for k=1:numel(fields)
                    S.(fields{k}) = get_param(block_path, fields{k});
                end
            end
            report{numel(report) + 1} = S;
        end
        close_system(base_name, 0);
    catch Me
        fprintf(Me.getReport());
        fprintf('couldnt load model %s\n',base_name );
    end
end
isUnique = true(size(report));

for ii = 1:length(report)-1
    for jj = ii+1:length(report)
        if isequal(report(ii),report(jj))
            isUnique(ii) = false;
            break;
        end
    end
end

report(~isUnique) = [];

save   all_blks_options report

end

