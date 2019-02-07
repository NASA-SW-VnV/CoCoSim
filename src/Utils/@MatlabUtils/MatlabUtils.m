classdef MatlabUtils
    %MatlabUtils contains all functions help in coding in Matlab.
    properties
    end
    
    methods (Static = true)
        
        %% Matlab IR
        tree = getExpTree(exp)
        %% concatenate 1-D vectors
        r = concat(varargin)
        %%
        out = naming(nomsim)        
        %%
        mkdir(path)
        % for fileNames such as "test.LUSTREC.lus" it should returns "test"
        fname = fileBase(path)
        %%
        st = gcd(T)
        %%
        diff1in2  = setdiff_struct( struct2, struct1, fieldname )
        res = structUnique(struct2, fieldname)        
        %% removeEmpty
        l = removeEmpty(l)
        %%
        tf = startsWith(s, pattern)
        %%
        tf = endsWith(s, pattern)
        %%
        res = contains(str, pattern)
        %% delete files using regular expressions:
        %e.g. rm *_PP.slx
        reg_delete(basedir, reg_exp)
       
        %% Concat cell array with a specific delimator
        joinedStr = strjoin(str, delimiter)
        str = strescape(str)
        %--------------------------------------------------------------------------
        c = escapeChar(c)
        %% This function for developers
        % open all files that contains a String
        whoUse(folder, str)

        openAllFilesContainingString(folder, str)
        
        terminate(modelName)
        
        count = getNbLines(file)

        F = allMatlabFilesExceeds(folder, n)

        
    end
    
end

