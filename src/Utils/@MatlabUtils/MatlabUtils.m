classdef MatlabUtils
    %MatlabUtils contains all functions help in coding in Matlab.
    properties
    end
    
    methods (Static = true)
        
        tree = getExpTree(exp)% Matlab IR
        r = concat(varargin)% concatenate 1-D vectors
        out = naming(nomsim)        
        mkdir(path)
        fname = fileBase(path)
        st = gcd(T)
        diff1in2  = setdiff_struct( struct2, struct1, fieldname )
        res = structUnique(struct2, fieldname)        
        l = removeEmpty(l)% removeEmpty
        tf = startsWith(s, pattern)
        tf = endsWith(s, pattern)
        res = contains(str, pattern)
        reg_delete(basedir, reg_exp)% delete files using regular expressions:e.g. rm *_PP.slx
        % Concat cell array with a specific delimator
        joinedStr = strjoin(str, delimiter)
        str = strescape(str)
        c = escapeChar(c)
        
        %% This function for developers
        % open all files that contains a String
        whoUse(folder, str)
        openAllFilesContainingString(folder, str)
        terminate(modelName)
        count = getNbLines(file)
        F = allMatlabFilesExceeds(folder, n)
        [pList, found, alreadyHandled] = requiredProducts(filepath, alreadyHandled);

        
    end
    
end

