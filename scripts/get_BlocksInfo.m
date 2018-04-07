function [report] = get_BlocksInfo(folder)
%GET_BLOCKSTYPE Summary of this function goes here
%   Detailed explanation goes here
bdclose('all')
slx_files = dir(fullfile(folder,'**', '*.slx'));
mdl_files = dir(fullfile(folder,'**', '*.mdl')) ;
all_files = [slx_files; mdl_files];
report = {};
CommonParameters = {'CompiledSampleTime', 'CompiledPortDataTypes', ...
    'CompiledPortDimensions', 'CompiledPortWidths', ...
    'CompiledPortComplexSignals',...
    'Ports'};
for i=1:numel(all_files)
    if isfield(all_files(i), 'folder')
        file_dir = all_files(i).folder;
        [~, base_name, ~] = fileparts( all_files(i).name);
    else
        [file_dir, base_name, ~] = fileparts( all_files(i).name);
    end
    try
        bdclose('all')
        load_system(fullfile(file_dir, ...
            all_files(i).name));
        list_of_all_blocks = find_system(base_name, ...
            'LookUnderMasks', 'all');
        Cmd = [base_name, '([], [], [], ''compile'');'];
        eval(Cmd);
        for j=2:numel(list_of_all_blocks)
            block_path = list_of_all_blocks{j};
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
            S.Mask = get_param(block_path, 'Mask');
            S.MaskType = get_param(block_path, 'MaskType');
            
            for k=1:numel(CommonParameters)
                S.(CommonParameters{k}) = get_param(block_path, CommonParameters{k});
            end
            
            report{numel(report) + 1} = S;
        end
        Cmd = [base_name, '([], [], [], ''term'');'];
        eval(Cmd);
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

