classdef MenuUtils
    %MenuUtils contains functions common to Menu functions
    
    properties
    end
    
    methods (Static = true)
      
        
        %% get function handle from its path
        function handle = funPath2Handle(fullpath)
            oldDir = pwd;
            [dirname,funName,~] = fileparts(fullpath);
            cd(dirname);
            handle = str2func(funName);
            cd(oldDir);
        end
    end
    
end

