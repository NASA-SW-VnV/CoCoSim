%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% InnerTransitions and  OuterTransitions Nodes
function  [external_nodes, external_libraries ] = ...
        write_TransitionsNodes(state, data_map)
    %L = nasa_toLustre.ToLustreImport.L;
    %import(L{:})
    external_nodes = {};
    [node, external_libraries] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.get_InnerTransitionsNode(state, data_map);
    if ~isempty(node)
        external_nodes{end+1} = node;
    end

    [node,  external_libraries_i] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.get_OuterTransitionsNode(state, data_map);
    if ~isempty(node)
        external_nodes{end+1} = node;
    end
    external_libraries = [external_libraries, external_libraries_i];
end

