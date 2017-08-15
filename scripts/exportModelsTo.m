function exportModelsTo(folder_Path, version)

if nargin==0
    [file_path, ~, ~] = fileparts(mfilename('fullpath'));
    folder_Path = fileparts(file_path);
end

if nargin < 2
    version = 'R2014a';
end



mdl_models = dir(fullfile(folder_Path,'**/*.mdl'));
slx_models = dir(fullfile(folder_Path,'**/*.slx'));
models = [mdl_models; slx_models];


for i=1:numel(models)
    m = models(i);
    display(m.name);
    full_path = fullfile(m.folder, m.name);
    try
        info = Simulink.MDLInfo(full_path);
        
        if str2double(info.SimulinkVersion)> 8.3
            
            fprintf('saving model %s in %s format\n', m.name, version);
            load_system(full_path);
            [path, base_name, ext] = fileparts(full_path);
            get_param(base_name,'Modelversionformat')
            target_filename = fullfile(path, strcat(base_name, '_tmp',ext));
            
            Simulink.exportToVersion(base_name,target_filename,version);
            close_system(full_path,1);
            delete(full_path);
            copyfile(target_filename, full_path);
            delete(target_filename);
            delete(strcat(full_path,'.r20*'));
            disp('Done');
        end
        
        
    catch ME
        display(ME.getReport());
        continue;
    end
    
end
bdclose('all')
end