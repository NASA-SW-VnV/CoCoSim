%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef MenuUtils
    %MenuUtils contains functions common to Menu functions
    
    properties
    end
    
    methods (Static = true)
        
        
        %% get function handle from its path
        function handle = funPath2Handle(fullpath)
            oldDir = pwd;
            [dirname,funName,~] = fileparts(which(fullpath));
            cd(dirname);
            handle = str2func(funName);
            cd(oldDir);
        end
        
        
        function fname = get_file_name(gcs)
            names = regexp(gcs,'/','split');
            fname = get_param(names{1},'FileName');
        end
    end
    
end

