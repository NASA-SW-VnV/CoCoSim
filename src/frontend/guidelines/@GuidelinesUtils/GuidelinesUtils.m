classdef GuidelinesUtils
    % utilities functions for checking model against supported guidelines
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods(Static)
        [results, numFail] = process_find_system_results(fsList,...
                title, varargin)
        
        allowedCharList = allowedChars(model,options)      
        
        newList = ppSignalNames(list)

    end
end

