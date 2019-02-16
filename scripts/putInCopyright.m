% this function traverse files in the workingDir, looks for 'Copyright (c)'
%   if not found, it will put in the Copyright text, does not do this for
%   subfolders
credit = 'Hamza';
%credit = 'Khanh';
workDir = '/Users/ktrinh/cocosim/cocosim2/src/backEnd/extra_options';
searchString = 'Copyright (c)';

cpRight{1} = '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
cpRight{2} = '% Copyright (c) 2017 United States Government as represented by the';
cpRight{3} = '% Administrator of the National Aeronautics and Space Administration.';
cpRight{4} = '% All Rights Reserved.';
cpRight{5} = '% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>';
cpRight{6} = '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
cpRight{7} = ' ';
dirInfo = dir(workDir);
for i=1:numel(dirInfo)
    if strfind(dirInfo(i).name,'putInCopyright')   % don't modify this file
        continue;
    end
    if dirInfo(i).isdir
        fprintf('%s is a directory\n',dirInfo(i).name);
        continue;
    end
    curFile = fopen(sprintf('%s/%s',workDir,dirInfo(i).name),'r');  %read file through 1st
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
    fclose(curFile);    % close read file
    
    if numberCopyrightFound < 1
        fprintf('No Copyright in file %s, adding Copyright text to it',dirInfo(i).name);
        curFile = fopen(sprintf('%s/%s',workDir,dirInfo(i).name),'w');  % open for modification
        
        if strfind(credit,'Khanh')
            cpRight{5} = '    % Author: khanh Trinh <khanh.v.trinh@nasa.gov>';
        end        
        
        % write copyright first
        for j=1:numel(cpRight)
            fprintf(curFile,'%s\n',cpRight{j});  
        end
        % write file content
        for j=1:numel(tlines)
            fprintf(curFile,'%s\n',tlines{j});  
        end        
        fclose(curFile); 
    end
%     
%     if numberCopyrightFound > 1
%         fprintf('More than 1 Copyright in file %s, removing 1st 7 lines',dirInfo(i).name);
%         curFile = fopen(sprintf('%s/%s',workDir,dirInfo(i).name),'w');  % open for modification
%         
%         % write file content skipping first 7 lines
%         for j=8:numel(tlines)
%             fprintf(curFile,'%s\n',tlines{j});  
%         end        
%         fclose(curFile); 
%     end
    fprintf('file %s, number of Copyright: %d\n',dirInfo(i).name,numberCopyrightFound);
    
end