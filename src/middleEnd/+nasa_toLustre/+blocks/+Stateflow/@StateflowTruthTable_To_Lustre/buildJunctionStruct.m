%StateflowTruthTable_To_Lustre: transform Table to graphical function.
% Then use StateflowGraphicalFunction_To_Lustre
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function junc = buildJunctionStruct(tablePath)
    junc.Id = nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.incrementID();
    junc.Name = sprintf('Junction%d', junc.Id);
    junc.Path = strcat (tablePath, '/',junc.Name);
    junc.Origin_path = strcat (tablePath, '/',junc.Name);
    junc.Type = 'CONNECTIVE';

end
