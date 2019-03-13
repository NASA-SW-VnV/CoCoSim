classdef BUtils    
    %BUTILS Summary of this class goes here
    %   Detailed explanation goes here
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    properties
    end
    
    methods (Static = true)
        
        [obs_pos] = get_obs_position(parent_subsystem)

        %%
        new_name = adapt_block_name(var_name, ID)

        %%
        block_path  = get_unique_block_name(block_path)

        %% Get the block name from path
        out = naming_alone(nomsim)

        %%
        data = read_json(contract_path)

        %%
         force_inports_DT(block_name)

        res = isLastModified(old_file1, new_file2)

        status = check_files_exist(varargin)

    end
    
end

