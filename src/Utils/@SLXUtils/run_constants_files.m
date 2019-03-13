%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

%% run constants files
function run_constants_files(const_files)
    const_files_bak = const_files;
    try
        const_files = evalin('base', const_files);
    catch
        const_files = const_files_bak;
    end

    if iscell(const_files)
        for i=1:numel(const_files)
            if strcmp(const_files{i}(end-1:end), '.m')
                evalin('base', ['run ' const_files{i} ';']);
            else
                vars = load(const_files{i});
                field_names = fieldnames(vars);
                for j=1:numel(field_names)
                    % base here means the current Matlab workspace
                    assignin('base', field_names{j}, vars.(field_names{j}));
                end
            end
        end
    elseif ischar(const_files)
        if strcmp(const_files(end-1:end), '.m')
            evalin('base', ['run ' const_files ';']);
        else
            vars = load(const_files);
            field_names = fieldnames(vars);
            for j=1:numel(field_names)
                % base here means the current Matlab workspace
                assignin('base', field_names{j}, vars.(field_names{j}));
            end
        end
    end
end

