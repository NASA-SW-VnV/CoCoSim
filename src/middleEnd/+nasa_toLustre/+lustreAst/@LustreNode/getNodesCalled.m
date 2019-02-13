%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% This function is used by KIND2 LustreProgram.print()
function nodesCalled = getNodesCalled(obj)
    nodesCalled = {};
    function addNodes(objects)
        if iscell(objects)
            for i=1:numel(objects)
                nodesCalled = [nodesCalled, objects{i}.getNodesCalled()];
            end
        else
            nodesCalled = [nodesCalled, objects.getNodesCalled()];
        end
    end
    addNodes(obj.localContract);
    addNodes(obj.bodyEqs);
end

