%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [pList, found, alreadyHandled] = requiredProducts(filepath, alreadyHandled)
    if nargin < 2
        alreadyHandled = {};
    end
    alreadyHandled{end+1} = filepath;
    [parent, fname, ~] = fileparts(filepath);
    [fList,pList] = matlab.codetools.requiredFilesAndProducts(filepath,'toponly');
    pList = pList(arrayfun(@(x) x.Certain, pList, 'UniformOutput', true));
    fprintf('File %s in %s has %d dependancies and %d products\n', ...
        fname, parent, numel(fList), numel(pList));
    found = false;
    if numel(pList) > 1
        found = true;
        return;
    end
    for i=1:length(fList)
        if ismember(fList{i},alreadyHandled)
            continue;
        end
        [pList, found, alreadyHandled] = MatlabUtils.requiredProducts(fList{i},alreadyHandled);
        if found
            break;
        end
    end
end

