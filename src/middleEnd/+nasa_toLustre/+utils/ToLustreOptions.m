classdef ToLustreOptions < handle
    %ToLustreOptions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant)
        % ToLustre options
        NODISPLAY = 'nodisplay';
        FORCE_CODE_GEN = 'forceCodeGen';
        SKIP_SF_ACTIONS_CHECK = 'skip_sf_actions_check';
        SKIP_CODE_OPTIMIZATION = 'skip_optim';
        SKIP_COMPATIBILITY = 'skip_unsupportedblocks';
        SKIP_DEFECTED_PP = 'skip_defected_pp';
        SKIP_PP = 'skip_pp';
        GEN_PP_VERIF = 'gen_pp_verif'; 
        USE_MORE_PRECISE_ABSTRACTION = 'use_more_precise_abstraction';
    end
    
   
end
