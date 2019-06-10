classdef ToLustreImport < handle
    %ToLustreImport
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant)
        L = {...
            'nasa_toLustre.*',...
            'nasa_toLustre.blocks.*', ...
            'nasa_toLustre.blocks.Stateflow.*', ...
            'nasa_toLustre.blocks.Stateflow.utils.*', ...
            'nasa_toLustre.frontEnd.*', ...
            'nasa_toLustre.IR_pp.internalRep_pp', ...
            'nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils', ...
            'nasa_toLustre.lustreAst.*', ...
            'nasa_toLustre.utils.*' ...
            };
    end
    
   
end
