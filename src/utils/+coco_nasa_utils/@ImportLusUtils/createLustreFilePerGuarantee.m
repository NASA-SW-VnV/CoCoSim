function lustreFilePaths = createLustreFilePerGuarantee(lustreFilePath, output_dir)
    [~, lustreFileName, lustreFileExtension] = fileparts(lustreFilePath);    
    
    fid = fopen(lustreFilePath, 'r');
    if fid == -1
        display_msg('Could not open Lustre file.', MsgType.ERROR, 'TOLUSTRE','');
    end

    lustreContent = fscanf(fid,'%c');
    guaranteePattern = '(\(\* Req text:).*?;';
    [guarantees, remainingContent] = regexp(lustreContent, guaranteePattern, 'match', 'split');

    %Filter out triple-newline entries from remainContent
    filteredIndices = arrayfun(@(RIDX) ~strcmp(remainingContent{RIDX}, sprintf('\n\n\n')), 1:length(remainingContent));
    remainingContent = remainingContent(filteredIndices);

    guaranteeNamePattern = '(?<=guarantee ").*?(?=")';
    guaranteeNames = regexp(lustreContent,guaranteeNamePattern,'match');
    lustreFilePaths = {};
    for i=1:length(guaranteeNames)
        lustreOutputDir = fullfile(output_dir, guaranteeNames{i});        
        if ~exist(lustreOutputDir, 'dir'); coco_nasa_utils.MatlabUtils.mkdir(lustreOutputDir); end
        newLustreFileName = fullfile(lustreOutputDir,strcat(guaranteeNames{i},lustreFileExtension));
        lustreFilePaths{end+1} = newLustreFileName;
        newLustreFile = fopen(newLustreFileName, 'w');
        
        if fid == -1
            display_msg('Could not open Lustre file.', MsgType.ERROR, 'TOLUSTRE','');
        end
        
        for j=1:length(remainingContent)
            if j ~= length(remainingContent)
                fprintf(newLustreFile,'%s',remainingContent{j});
            else
                fprintf(newLustreFile,'%s',guarantees{i});
                fprintf(newLustreFile,'%s',remainingContent{j});
            end
        end        
        fclose(newLustreFile);
    end
    fclose(fid);
end