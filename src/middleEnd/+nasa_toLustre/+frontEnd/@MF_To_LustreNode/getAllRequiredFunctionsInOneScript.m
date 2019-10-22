function [script, failed] = getAllRequiredFunctionsInOneScript(blk)
    %% copy all required functions in one script
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %
    %
    failed = false;
    script = blk.Script;
    
    %No need for this at the moment
%     % remove multi-line comment
%     script = regexprep(script,'\%\{.+\%\}', '');
%     % remove one-line comment
%     script = regexprep(script,'\%[^\n]*', '');

    func_path = strcat(tempname, '.m');
    [fun_dir, ~, ~] = fileparts(func_path);
    PWD = pwd;
    cd(fun_dir);
    fid = fopen(func_path, 'w');
    if fid < 0
        display_msg(sprintf('Could not open file "%s" for writing', func_path), ...
            MsgType.DEBUG, 'getMFunctionCode', '');
        failed = true;
        return;
    end
    % print % in file
    script = strrep(script, '%', '%%');
    script = strrep(script, '\', '\\');
    fprintf(fid, script);
    fclose(fid);
    fList = matlab.codetools.requiredFilesAndProducts(func_path);
    if numel(fList) > 1
        for i=2:length(fList)
            script = sprintf('%s\n%s', script, fileread(fList{i}));
        end
    end

    try delete(func_path), catch, end
    cd(PWD);
end
