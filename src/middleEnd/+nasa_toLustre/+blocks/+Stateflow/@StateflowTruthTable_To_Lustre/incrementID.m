
%StateflowTruthTable_To_Lustre: transform Table to graphical function.
% Then use StateflowGraphicalFunction_To_Lustre
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function id_out = incrementID()
    persistent id;
    if isempty(id)
        id = 0;
    end
    id = id+1;
    id_out = id;
end
