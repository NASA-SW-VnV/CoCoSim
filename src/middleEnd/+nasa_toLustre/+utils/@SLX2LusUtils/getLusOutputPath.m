function [lus_path, mat_file, plu_path] = getLusOutputPath(output_dir, model_name, lus_backend)
    %GETLUSOUTPUTPATH refactors the path where lustre will be generated
    lustre_file_base = strcat(model_name,'.', lus_backend, '.lus');
    mat_file_base = strcat(model_name,'.', lus_backend, '.mat');
    lus_path = fullfile(output_dir, lustre_file_base);
    mat_file = fullfile(output_dir, mat_file_base);
    plu_path = '';
    if LusBackendType.isPRELUDE(lus_backend)
        plu_path = fullfile(output_dir, ...
            strcat(model_name, '.', lus_backend,'.plu'));
    end
end

