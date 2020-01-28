%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright © 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
classdef MatlabUtils
    %MatlabUtils contains all functions help in coding in Matlab.
    properties
    end
    
    methods (Static = true)
        
        tree = getExpTree(exp)% Matlab IR
        r = concat(varargin)% concatenate 1-D vectors
        out = naming(nomsim)
        mkdir(path)% recursively mkdir from top to bottom
        status = rmdir(path)% recursively rmdir empty folders from bottom to top
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
        
        %% cell cartesian product
        c2 = cartesian(varargin)
        c2 = cellCartesianProduct(c1)
        %% get package prefix
        path_prefix = getPackagePrefix(f_parent, f_name)
        
        %% json encode, decode
        json = jsondecode(s)
        json = jsonencode(s)
        %% This function for developers
        % open all files that contains a String
        whoUse(folder, str)
        openAllFilesContainingString(folder, str)
        
        
        
        count = getNbLines(file)
        F = allMatlabFilesExceeds(folder, n)
        [pList, found, alreadyHandled] = requiredProducts(filepath, alreadyHandled);
        

        
    end
    
end

