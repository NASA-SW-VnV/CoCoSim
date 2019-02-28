function [script, failed] = getAllRequiredFunctionsInOneScript(blk)
    %% copy all required functions in one script
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %L = nasa_toLustre.ToLustreImport.L;% Avoiding importing functions. Use direct indexing instead for safe call
    %import(L{:})
    failed = false;
    script = blk.Script;
    blk_name = nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
    func_path = fullfile(pwd, strcat(blk_name, '.m'));
    fid = fopen(func_path, 'w');
    if fid < 0
        display_msg(sprintf('Could not open file "%s" for writing', func_path), ...
            MsgType.DEBUG, 'getMFunctionCode', '');
        failed = true;
        return;
    end
    fprintf(fid, script);
    fclose(fid);
    fList = matlab.codetools.requiredFilesAndProducts(func_path);
    if numel(fList) > 1
        for i=2:length(fList)
            script = sprintf('%s\n%s', script, fileread(fList{i}));
        end
    end

    try delete(func_path), catch, end
end
