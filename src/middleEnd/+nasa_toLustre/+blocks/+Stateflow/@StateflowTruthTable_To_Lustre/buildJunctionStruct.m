%StateflowTruthTable_To_Lustre: transform Table to graphical function.
% Then use StateflowGraphicalFunction_To_Lustre
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function junc = buildJunctionStruct(tablePath)
    junc.Id = nasa_toLustre.blocks.Stateflow.StateflowTruthTable_To_Lustre.incrementID();
    junc.Name = sprintf('Junction%d', junc.Id);
    junc.Path = strcat (tablePath, '/',junc.Name);
    junc.Origin_path = strcat (tablePath, '/',junc.Name);
    junc.Type = 'CONNECTIVE';

end
