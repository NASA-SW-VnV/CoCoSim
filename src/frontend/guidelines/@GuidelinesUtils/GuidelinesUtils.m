classdef GuidelinesUtils
    % utilities functions for checking model against supported guidelines
    
    methods(Static)
        [results, numFail] = process_find_system_results(fsList,...
                title, varargin)
        
        allowedCharList = allowedChars(model,options)      
        
        newList = ppSignalNames(list)

    end
end

