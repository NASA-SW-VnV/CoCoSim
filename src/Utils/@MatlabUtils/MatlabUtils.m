%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
classdef MatlabUtils
    %MatlabUtils contains all functions help in coding in Matlab.
    properties
    end
    
    methods (Static = true)
        
        tree = getExpTree(exp)% Matlab IR
        r = concat(varargin)% concatenate 1-D vectors
        out = naming(nomsim)
        mkdir(path)% recursively mkdir from top to bottom
        rmdir(path)% recursively rmdir empty folders from bottom to top
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
        f = map()
        f = mapc()
        f = iif()
        %% create random vectors
        vector = construct_random_integers(nb_iterations, IMIN, IMAX, dt, dim)
        vector = construct_random_booleans(nb_iterations, IMIN, IMAX, dim)
        vector = construct_random_doubles(nb_iterations, IMIN, IMAX,dim)
        %% This function for developers
        % open all files that contains a String
        whoUse(folder, str)
        openAllFilesContainingString(folder, str)
        terminate(modelName)
        count = getNbLines(file)
        F = allMatlabFilesExceeds(folder, n)
        [pList, found, alreadyHandled] = requiredProducts(filepath, alreadyHandled);
        exportModelsTo(folder_Path, version)

        
    end
    
end

