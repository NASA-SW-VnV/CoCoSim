
% function to search folder and subfolder for string
function [numFileRead, numFileModified, typesFound] = ...
    search_folder_and_subfolders_for_string(dirInfo,searchString,searchType)
    
    numFileRead = 0;
    numFileModified = 0;
    typesFound = {};
    for i=1:numel(dirInfo)
        if strcmp(dirInfo(i).name,'.')
            continue;
        end
        if strcmp(dirInfo(i).name,'..')
            continue;
        end        
        if dirInfo(i).isdir
            %fprintf('%s is a directory\n',dirInfo(i).name);
            if strcmp(dirInfo(i).name,'lustret')
                continue;
            end
            curDirectory = what(dirInfo(i).name);
            if isempty(curDirectory)
                continue;
            end
            curDirInfo = dir(curDirectory(1).path);
            [nRead, numModified, curTypesFound] = ...
                search_folder_and_subfolders_for_string(curDirInfo,searchString,searchType);
            numFileRead = numFileRead + nRead;
            numFileModified = numFileModified + numModified;
            for j=1:numel(curTypesFound)
                if isempty(ismember(typesFound,curTypesFound{j}))
                    typesFound{end+1} = curTypesFound{j};
                end                
            end

        else 
            %fprintf('     file %s \n',which(dirInfo(i).name));
            [~,~,ext] = fileparts(which(dirInfo(i).name));
            if strcmp(ext,'.fig')
                fprintf('     file %s \n',which(dirInfo(i).name));
            end
            if isempty(ismember(typesFound,ext))
                typesFound{end+1} = ext;
            end       
            if isempty(ismember(searchType,ext))
                continue;
            end   
            curFile = fopen(which(dirInfo(i).name),'r');  %read file through 1st
            if curFile < 0
                continue;
            end


            tline = fgetl(curFile);
            tlines = cell(0,1);
            numberCopyrightFound = 0;
            while ischar(tline)
                if strfind(tline,searchString)
                    numberCopyrightFound = numberCopyrightFound + 1;
                end
                tlines{end+1,1} = tline;
                tline = fgetl(curFile);
            end
            numFileRead = numFileRead + 1;
            fclose(curFile);    % close read file    
            

            if numberCopyrightFound < 1
                fprintf('No Copyright in file %s, adding Copyright text to it\n',dirInfo(i).name);
                %curFile = fopen(sprintf('%s/%s',workDir,dirInfo(i).name),'w');  % open for modification
                curFile = fopen(which(dirInfo(i).name),'w');  % open for modification
                if curFile < 0
                    continue;
                end                
                cpRight{1} = '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
                cpRight{2} = '% Copyright (c) 2017 United States Government as represented by the';
                cpRight{3} = '% Administrator of the National Aeronautics and Space Administration.';
                cpRight{4} = '% All Rights Reserved.';
                cpRight{5} = '% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>';
                cpRight{6} = '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
                cpRight{7} = ' ';

%                 if strfind(credit,'Khanh')
%                     cpRight{5} = '    % Author: khanh Trinh <khanh.v.trinh@nasa.gov>';
%                 end        

                % write copyright first
                for j=1:numel(cpRight)
                    fprintf(curFile,'%s\n',cpRight{j});  
                end
                % write file content
                for j=1:numel(tlines)
                    fprintf(curFile,'%s\n',tlines{j});  
                end        
                numFileModified = numFileModified + 1;
                fclose(curFile); 
            end            

        end        

    end
end

